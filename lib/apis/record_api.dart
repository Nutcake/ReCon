import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bson/bson.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:recon/clients/api_client.dart';
import 'package:recon/models/records/asset_chunk.dart';
import 'package:recon/models/records/asset_diff.dart';
import 'package:recon/models/records/asset_manifest.dart';
import 'package:recon/models/records/asset_upload_data.dart';
import 'package:recon/models/records/cloudflare_chunk_result.dart';
import 'package:recon/models/records/json_template.dart';
import 'package:recon/models/records/preprocess_status.dart';
import 'package:recon/models/records/record.dart';
import 'package:recon/models/records/search_sort.dart';
import 'package:image/image.dart' as img;

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
    final encodedPath = Uri.encodeComponent(path);
    final response = await client.get("/users/${user ?? client.userId}/records?path=$encodedPath");
    client.checkResponse(response);
    final body = jsonDecode(response.body) as List;
    return body.map((e) => Record.fromMap(e)).toList();
  }

  static Future<List<Record>> getGroupRecordsAt(ApiClient client, {required String path, required String groupId}) async {
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

  static Future<PreprocessStatus> getPreprocessStatus(ApiClient client, {required PreprocessStatus preprocessStatus}) async {
    final response = await client.get("/users/${preprocessStatus.ownerId}/records/${preprocessStatus.recordId}/preprocess/${preprocessStatus.id}");
    client.checkResponse(response);
    final body = jsonDecode(response.body);
    return PreprocessStatus.fromMap(body);
  }

  static Future<AssetUploadData> announceAssetUpload(ApiClient client, {required AssetManifest manifest}) async {
    final response = await client.post("/users/${client.userId}/assets/${manifest.hash}/upload?size=${manifest.bytes}");
    client.checkResponse(response);
    final body = jsonDecode(response.body);
    return AssetUploadData.fromMap(body);
  }

  static Future<void> finalizeUpload(ApiClient client, {required AssetUploadData uploadData}) async {
    final response = await client.patch("/users/${client.userId}/assets/${uploadData.hash}/upload/${uploadData.id}", body: jsonEncode(uploadData.toMap()));
    client.checkResponse(response);
  }

  static Future<AssetUploadData> getUploadInfo(ApiClient client, {required AssetUploadData uploadData}) async {
    final response = await client.patch("/users/${client.userId}/assets/${uploadData.hash}/upload/${uploadData.id}", body: jsonEncode(uploadData.toMap()));
    client.checkResponse(response);
    final body = jsonDecode(response.body);
    return AssetUploadData.fromMap(body);
  }

  static Future<void> _directAssetUpload({required AssetUploadData uploadData, required Uint8List assetData}) async {
    final response = await http.put(Uri.parse(uploadData.uploadEndpoint), headers: {"Upload-Key": uploadData.uploadKey, "Upload-Timestamp": uploadData.createdOn}, body: assetData);
    ApiClient.checkResponseCode(response);
  }

  static Future<CloudflareChunkResult> _chunkedAssetUpload({required AssetUploadData uploadData, required int chunkIndex, required Uint8List chunkData}) async {
    final response = await http.put(Uri.parse(uploadData.uploadEndpoint), headers: {"Upload-Key": uploadData.uploadKey, "Part-Number": chunkIndex.toString()}, body: chunkData);
    ApiClient.checkResponseCode(response);
    final body = jsonDecode(response.body);
    return CloudflareChunkResult.fromMap(body);
  }

  static Future<List<AssetUploadData>> _uploadAsset(
    ApiClient client, {
    required AssetManifest manifest,
    required Uint8List data,
    void Function(double progress)? progressCallback,
  }) async {
    final chunkedUploads = <AssetUploadData>[];
    final uploadData = await announceAssetUpload(client, manifest: manifest);
    if (uploadData.isDirectUpload) {
      await _directAssetUpload(uploadData: uploadData, assetData: data);
    } else {
      final chunks = data.slices(uploadData.chunkSize);
      for (final (cIdx, chunk) in chunks.indexed) {
        final chunkResult = await _chunkedAssetUpload(uploadData: uploadData, chunkIndex: cIdx + 1, chunkData: Uint8List.fromList(chunk));
        final chunkInfo = AssetChunk(index: cIdx, key: chunkResult.eTag);
        uploadData.chunks.add(chunkInfo);
        progressCallback?.call(cIdx / chunks.length);
      }
      chunkedUploads.add(uploadData);
    }
    await finalizeUpload(client, uploadData: uploadData);
    progressCallback?.call(1);
    return chunkedUploads;
  }

  static Future<Record> createRecord(ApiClient client, {required Record record, bool ensureFolder = false}) async {
    final response = await client.put("/users/${client.userId}/records/${record.id}?ensureFolder=$ensureFolder", body: jsonEncode(record.toMap()));
    client.checkResponse(response);
    final body = jsonDecode(response.body);
    return Record.fromMap(body);
  }

  static Future<Record> uploadImage(ApiClient client, {required File image, required String machineId, String? messageId, void Function(double progress)? progressCallback}) async {
    progressCallback?.call(0);
    final imageData = await image.readAsBytes();
    final cmd = img.Command()
      ..decodeImage(imageData)
      ..copyResize(width: 512)
      ..encodeJpg(quality: 90);
    final res = await cmd.executeThread();
    final thumbnail = res.outputBytes!;
    final imageManifest = AssetManifest.fromData(imageData);
    final thumbnailManifest = AssetManifest.fromData(thumbnail);
    final assetUri = "resdb:///${imageManifest.hash}${extension(image.path)}";
    final dataTree = JsonTemplate.image(imageResDb: assetUri, machineId: machineId);
    // Prefix FrDT header
    final bson = Uint8List.fromList([70, 114, 68, 84, 0, 0, 0, 0] + BsonCodec.serialize(dataTree).byteList);
    final bsonManifest = AssetManifest.fromData(bson);
    final assetManifest = {imageManifest: imageData, thumbnailManifest: thumbnail, bsonManifest: bson};

    final record = Record.local(
      name: "Photo from ReCon",
      recordType: RecordType.object,
      ownerId: client.userId,
      assetManifest: assetManifest.keys.toList(),
      assetUri: assetUri,
      tags: ["holder", "photo", "camera_photo", "texture_asset:$assetUri", "message_item", "message_id:$messageId"],
      lastModifyingMachineId: machineId,
    ).copyWith(thumbnailUri: () => "resdb:///${thumbnailManifest.hash}${extension(image.path)}");

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
    for (final diff in preproc.resultDiffs.where((element) => element.state == Diff.added && !(element.isUploaded ?? false))) {
      final dataKey = assetManifest.keys.firstWhere((element) => element.hash == diff.hash);
      final chunked = await _uploadAsset(client, manifest: diff, data: assetManifest[dataKey]!, progressCallback: (progress) => progressCallback?.call(0.2 + progress * 0.9));
      chunkedUploads.addAll(chunked);
    }

    for (var uploadData in chunkedUploads) {
      while (uploadData.uploadState != UploadState.uploaded) {
        uploadData = await getUploadInfo(client, uploadData: uploadData);
        if (uploadData.uploadState == UploadState.failed) {
          throw "Upload failed: Unknown cloud error when combining asset chunks";
        }
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    }

    await createRecord(client, record: record);

    progressCallback?.call(1);
    return record;
  }

  static Future<Record> uploadVoiceClip(
    ApiClient client, {
    required File voiceClip,
    required String machineId,
    String? messageId,
    void Function(double progress)? progressCallback,
  }) async {
    progressCallback?.call(0);

    final bytes = voiceClip.readAsBytesSync();
    final voiceManifest = AssetManifest.fromData(bytes);
    final assetManifests = {voiceManifest: bytes};

    final record = Record.local(
      name: "Voice Message",
      recordType: RecordType.audio,
      ownerId: client.userId,
      assetManifest: assetManifests.keys.toList(),
      assetUri: "resdb:///${voiceManifest.hash}${extension(voiceClip.path)}",
      tags: ["message_item", if (messageId != null) "message_id:$messageId"],
      lastModifyingMachineId: machineId,
    );

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
    for (final diff in preproc.resultDiffs.where((element) => element.state == Diff.added && !(element.isUploaded ?? false))) {
      final dataKey = assetManifests.keys.firstWhere((element) => element.hash == diff.hash);
      final chunked = await _uploadAsset(client, manifest: diff, data: assetManifests[dataKey]!, progressCallback: (progress) => progressCallback?.call(0.2 + progress * 0.9));
      chunkedUploads.addAll(chunked);
    }

    for (var uploadData in chunkedUploads) {
      while (uploadData.uploadState != UploadState.uploaded) {
        uploadData = await getUploadInfo(client, uploadData: uploadData);
        if (uploadData.uploadState == UploadState.failed) {
          throw "Upload failed: Unknown cloud error when combining asset chunks";
        }
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    }

    await createRecord(client, record: record);

    progressCallback?.call(1);
    return record;
  }

  static Future<Record> uploadRawFile(ApiClient client, {required File file, required String machineId, void Function(double progress)? progressCallback}) async {
    progressCallback?.call(0);
    progressCallback?.call(1);
    return Record.inventoryRoot();
  }
}
