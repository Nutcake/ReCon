import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import 'package:recon/clients/api_client.dart';
import 'package:recon/models/records/asset_chunk.dart';
import 'package:recon/models/records/asset_diff.dart';
import 'package:recon/models/records/asset_digest.dart';
import 'package:recon/models/records/asset_manifest.dart';
import 'package:recon/models/records/asset_upload_data.dart';
import 'package:recon/models/records/cloudflare_chunk_result.dart';
import 'package:recon/models/records/json_template.dart';
import 'package:recon/models/records/preprocess_status.dart';
import 'package:recon/models/records/record.dart';
import 'package:recon/models/records/resonite_db_asset.dart';
import 'package:recon/models/records/search_sort.dart';

class RecordApi {
  static Future<Record> getUserRecord(ApiClient client, {required String recordId, String? user}) async {
    final response = await client.get("/users/${user ?? client.userId}/records/$recordId");
    client.checkResponse(response);
    final body = jsonDecode(response.body) as Map;
    return Record.fromMap(body);
  }

  static Future<Record> getGroupRecordByPath(ApiClient client, {required String path, required String groupId}) async {
    final response = await client.get("/groups/$groupId/records/$path");
    client.checkResponse(response);
    final body = jsonDecode(response.body) as Map;
    return Record.fromMap(body);
  }

  static Future<List<Record>> searchWorldRecords(
    ApiClient client, {
    List<String> requiredTags = const [],
    SearchSortDirection sortDirection = SearchSortDirection.descending,
    SearchSortParameter sortParameter = SearchSortParameter.lastUpdateDate,
    int limit = 10,
    int offset = 0,
  }) async {
    final requestBody = {
      "requiredTags": requiredTags,
      "sortDirection": sortDirection.toString(),
      "sortBy": sortParameter.serialize(),
      "count": limit,
      "offset": offset,
      "recordType": "world",
    };
    final response = await client.post("/records/pagedSearch", body: jsonEncode(requestBody));
    client.checkResponse(response);
    final body = (jsonDecode(response.body) as Map)["records"] as List;
    return body.map((e) => Record.fromMap(e)).toList();
  }

  static Future<List<Record>> getUserRecordsAt(ApiClient client, {required String path, String? user}) async {
    final response = await client.get(Uri.encodeFull("/users/${user ?? client.userId}/records?path=$path"));
    client.checkResponse(response);
    final body = jsonDecode(response.body) as List;
    return body.map((e) => Record.fromMap(e)).toList();
  }

  static Future<List<Record>> getGroupRecordsAt(
    ApiClient client, {
    required String path,
    required String groupId,
  }) async {
    final response = await client.get("/groups/$groupId/records?path=$path");
    client.checkResponse(response);
    final body = jsonDecode(response.body) as List;
    return body.map((e) => Record.fromMap(e)).toList();
  }

  static Future<void> deleteRecord(ApiClient client, {required String recordId}) async {
    final response = await client.delete("/users/${client.userId}/records/$recordId");
    client.checkResponse(response);
  }

  static Future<PreprocessStatus> preprocessRecord(ApiClient client, {required Record record}) async {
    final body = jsonEncode(record.toMap());
    final response = await client.post("/users/${record.ownerId}/records/${record.id}/preprocess", body: body);
    client.checkResponse(response);
    final resultBody = jsonDecode(response.body);
    return PreprocessStatus.fromMap(resultBody);
  }

  static Future<PreprocessStatus> getPreprocessStatus(
    ApiClient client, {
    required PreprocessStatus preprocessStatus,
  }) async {
    final response = await client.get(
      "/users/${preprocessStatus.ownerId}/records/${preprocessStatus.recordId}/preprocess/${preprocessStatus.id}",
    );
    client.checkResponse(response);
    final body = jsonDecode(response.body);
    return PreprocessStatus.fromMap(body);
  }

  static Future<AssetUploadData> _beginAssetUpload(ApiClient client, {required AssetManifest manifest}) async {
    final response = await client.post("/users/${client.userId}/assets/${manifest.hash}/upload?size=${manifest.bytes}");
    client.checkResponse(response);
    final body = jsonDecode(response.body);
    return AssetUploadData.fromMap(body);
  }

  static Future<void> _directAssetUpload({required AssetUploadData uploadData, required Uint8List assetData}) async {
    final request = http.MultipartRequest(
      "PUT",
      Uri.parse(uploadData.uploadEndpoint),
    )
      ..files.add(
        http.MultipartFile.fromBytes(
          "file",
          assetData,
          filename: uploadData.hash,
          contentType: MediaType.parse("multipart/form-data"),
        ),
      )
      ..headers.addAll(
        {
          "Upload-Key": uploadData.uploadKey,
          "Upload-Timestamp": uploadData.createdOn.toIso8601String(),
        },
      );
    final response = await request.send();
    final bodyBytes = await response.stream.toBytes();
    ApiClient.checkResponseCode(http.Response.bytes(bodyBytes, response.statusCode));
  }

  static Future<CloudflareChunkResult> _chunkedAssetUpload({
    required AssetUploadData uploadData,
    required int chunkIndex,
    required Uint8List chunkData,
  }) async {
    final response = await http.put(
      Uri.parse(uploadData.uploadEndpoint),
      headers: {
        "Upload-Key": uploadData.uploadKey,
        "Part-Number": chunkIndex.toString(),
      },
      body: chunkData,
    );
    ApiClient.checkResponseCode(response);
    final body = jsonDecode(response.body);
    return CloudflareChunkResult.fromMap(body);
  }

  static Future<void> _finalizeUpload(ApiClient client, {required AssetUploadData uploadData}) async {
    final response = await client.patch(
      "/users/${client.userId}/assets/${uploadData.hash}/upload/${uploadData.id}",
      body: jsonEncode(uploadData.toMap()),
    );
    client.checkResponse(response);
  }

  static Future<AssetUploadData> _getUploadInfo(ApiClient client, {required AssetUploadData uploadData}) async {
    final response = await client.patch(
      "/users/${client.userId}/assets/${uploadData.hash}/upload/${uploadData.id}",
      body: jsonEncode(uploadData.toMap()),
    );
    client.checkResponse(response);
    final body = jsonDecode(response.body);
    return AssetUploadData.fromMap(body);
  }

  static Future<PreprocessStatus> tryPreprocessRecord(ApiClient client, {required Record record}) async {
    var status = await preprocessRecord(client, record: record);
    while (status.state == RecordPreprocessState.preprocessing) {
      await Future.delayed(const Duration(seconds: 1));
      status = await getPreprocessStatus(client, preprocessStatus: status);
    }

    if (status.state != RecordPreprocessState.success) {
      throw "Record Preprocessing failed: ${status.failReason}";
    }
    return status;
  }

  static Future<AssetUploadData> beginUploadAsset(ApiClient client, {required ResoniteDBAsset asset}) async {
    final response = await client.post("/users/${client.userId}/assets/${asset.hash}/chunks");
    client.checkResponse(response);
    final body = jsonDecode(response.body);
    final res = AssetUploadData.fromMap(body);
    if (res.uploadState == UploadState.failed) throw body;
    return res;
  }

  static Future<Record> upsertRecord(ApiClient client, {required Record record, bool ensureFolder = false}) async {
    final response = await client.put(
      "/users/${client.userId}/records/${record.id}?ensureFolder=$ensureFolder",
      body: jsonEncode(record.toMap()),
    );
    client.checkResponse(response);
    final body = jsonDecode(response.body);
    return Record.fromMap(body);
  }

  static Future<void> uploadAsset(
    ApiClient client, {
    required AssetUploadData uploadData,
    required String filename,
    required ResoniteDBAsset asset,
    required Uint8List data,
    void Function(double number)? progressCallback,
  }) async {
    for (var i = 0; i < uploadData.totalChunks; i++) {
      progressCallback?.call(i / uploadData.totalChunks);
      final offset = i * uploadData.chunkSize;
      final end = (i + 1) * uploadData.chunkSize;
      final request = http.MultipartRequest(
        "POST",
        ApiClient.buildFullUri("/users/${client.userId}/assets/${asset.hash}/chunks/$i"),
      )
        ..files.add(
          http.MultipartFile.fromBytes(
            "file",
            data.getRange(offset, min(end, data.length)).toList(),
            filename: filename,
            contentType: MediaType.parse("multipart/form-data"),
          ),
        )
        ..headers.addAll(client.authorizationHeader);
      final response = await request.send();
      final bodyBytes = await response.stream.toBytes();
      client.checkResponse(http.Response.bytes(bodyBytes, response.statusCode));
      progressCallback?.call(1);
    }
  }

  static Future<void> finishUpload(ApiClient client, {required ResoniteDBAsset asset}) async {
    final response = await client.patch("/users/${client.userId}/assets/${asset.hash}/chunks");
    client.checkResponse(response);
  }

  static Future<void> uploadAssets(
    ApiClient client, {
    required List<AssetDigest> assets,
    void Function(double progress)? progressCallback,
  }) async {
    progressCallback?.call(0);
    for (var i = 0; i < assets.length; i++) {
      final totalProgress = i / assets.length;
      progressCallback?.call(totalProgress);
      final entry = assets[i];
      final uploadData = await beginUploadAsset(client, asset: entry.asset);
      if (uploadData.uploadState == UploadState.failed) {
        throw "Asset upload failed: ${uploadData.uploadState.name}";
      }
      await uploadAsset(
        client,
        uploadData: uploadData,
        asset: entry.asset,
        data: entry.data,
        filename: entry.name,
        progressCallback: (progress) => progressCallback?.call(totalProgress + progress * 1 / assets.length),
      );
      await finishUpload(client, asset: entry.asset);
    }
    progressCallback?.call(1);
  }

  static Future<Record> uploadImage(
    ApiClient client, {
    required File image,
    required String machineId,
    void Function(double progress)? progressCallback,
  }) async {
    progressCallback?.call(0);
    final imageDigest = await AssetDigest.fromData(await image.readAsBytes(), basename(image.path));
    final imageData = await decodeImageFromList(imageDigest.data);
    final filename = basenameWithoutExtension(image.path);

    final objectJson = jsonEncode(
      JsonTemplate.image(
        imageUri: imageDigest.dbUri,
        filename: filename,
        width: imageData.width,
        height: imageData.height,
      ).data,
    );
    final objectBytes = Uint8List.fromList(utf8.encode(objectJson));

    final objectDigest = await AssetDigest.fromData(objectBytes, "${basenameWithoutExtension(image.path)}.json");

    final digests = [imageDigest, objectDigest];

    final record = Record.inventoryRoot();
    progressCallback?.call(.1);
    final status = await tryPreprocessRecord(client, record: record);
    final toUpload = status.resultDiffs.whereNot((element) => element.isUploaded ?? false);
    progressCallback?.call(.2);

    await uploadAssets(
      client,
      assets: digests.where((digest) => toUpload.any((diff) => digest.asset.hash == diff.hash)).toList(),
      progressCallback: (progress) => progressCallback?.call(.2 + progress * .6),
    );
    await upsertRecord(client, record: record);
    progressCallback?.call(1);
    return record;
  }

  static Future<List<AssetUploadData>> _uploadAsset(
    ApiClient client, {
    required AssetManifest manifest,
    required Uint8List data,
    void Function(double progress)? progressCallback,
  }) async {
    final chunkedUploads = <AssetUploadData>[];
    final uploadData = await _beginAssetUpload(client, manifest: manifest);
    if (uploadData.isDirectUpload) {
      await _directAssetUpload(uploadData: uploadData, assetData: data);
    } else {
      final chunks = data.slices(uploadData.chunkSize);
      for (final (cIdx, chunk) in chunks.indexed) {
        final chunkResult = await _chunkedAssetUpload(
          uploadData: uploadData,
          chunkIndex: cIdx + 1,
          chunkData: Uint8List.fromList(chunk),
        );
        final chunkInfo = AssetChunk(index: cIdx, key: chunkResult.eTag);
        uploadData.chunks.add(chunkInfo);
        progressCallback?.call(cIdx / chunks.length);
      }
      chunkedUploads.add(uploadData);
    }
    await _finalizeUpload(client, uploadData: uploadData);
    progressCallback?.call(1);
    return chunkedUploads;
  }

  static Future<Record> uploadVoiceClip(
    ApiClient client, {
    required File voiceClip,
    required String machineId,
    void Function(double progress)? progressCallback,
  }) async {
    progressCallback?.call(0);

    final filename = basenameWithoutExtension(voiceClip.path);
    final bytes = voiceClip.readAsBytesSync();
    final voiceManifest = AssetManifest.fromData(bytes);
    final assetManifests = {voiceManifest: bytes};

    final record = Record.local(
        name: "Voice Message",
        recordType: RecordType.audio,
        ownerId: client.userId,
        assetManifest: assetManifests.keys.toList(),
        assetUri: "resdb:///${voiceManifest.hash}.${extension(voiceClip.path)}");

    var preproc = await preprocessRecord(client, record: record);
    while (preproc.state != RecordPreprocessState.success) {
      preproc = await getPreprocessStatus(client, preprocessStatus: preproc);
      if (preproc.state == RecordPreprocessState.failed) {
        throw "Failed to upload asset: ${preproc.failReason}";
      }
      progressCallback?.call(preproc.progress * 0.2);
      await Future.delayed(const Duration(seconds: 1));
    }
    final chunkedUploads = <AssetUploadData>[];
    for (final diff in preproc.resultDiffs.where(
      (element) => element.state == Diff.added && !(element.isUploaded ?? false),
    )) {
      final dataKey = assetManifests.keys.firstWhere(
        (element) => element.hash == diff.hash,
      );
      final chunked = await _uploadAsset(
        client,
        manifest: diff,
        data: assetManifests[dataKey]!,
        progressCallback: (progress) => progressCallback?.call(0.2 + progress * 0.9),
      );
      chunkedUploads.addAll(chunked);
    }

    for (var uploadData in chunkedUploads) {
      while (uploadData.uploadState != UploadState.uploaded) {
        uploadData = await _getUploadInfo(client, uploadData: uploadData);
        if (uploadData.uploadState == UploadState.failed) {
          throw "Upload failed: Unknown cloud error when combining asset chunks";
        }
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    }

    await upsertRecord(client, record: record);

    progressCallback?.call(1);
    return record;
  }

  static Future<Record> uploadRawFile(
    ApiClient client, {
    required File file,
    required String machineId,
    void Function(double progress)? progressCallback,
  }) async {
    progressCallback?.call(0);
    progressCallback?.call(1);
    return Record.inventoryRoot();
  }
}
