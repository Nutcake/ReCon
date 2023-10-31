import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:recon/models/records/asset_digest.dart';
import 'package:recon/models/records/json_template.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'package:recon/clients/api_client.dart';
import 'package:recon/models/records/asset_upload_data.dart';
import 'package:recon/models/records/resonite_db_asset.dart';
import 'package:recon/models/records/preprocess_status.dart';
import 'package:recon/models/records/record.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

class RecordApi {
  static Future<Record> getUserRecord(ApiClient client, {required String recordId, String? user}) async {
    final response = await client.get("/users/${user ?? client.userId}/records/$recordId");
    client.checkResponse(response);
    final body = jsonDecode(response.body) as Map;
    return Record.fromMap(body);
  }

  static Future<List<Record>> getUserRecordsAt(ApiClient client, {required String path, String? user}) async {
    final response = await client.get(Uri.encodeFull("/users/${user ?? client.userId}/records?path=$path"));
    client.checkResponse(response);
    final body = jsonDecode(response.body) as List;
    return body.map((e) => Record.fromMap(e)).toList();
  }

  static Future<List<Record>> getGroupRecordsAt(ApiClient client, {required String path, required String groupId}) async {
    final response = await client.get("/users/$groupId/records?path=$path");
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
    final response = await client.post(
        "/users/${record.ownerId}/records/${record.id}/preprocess", body: body);
    client.checkResponse(response);
    final resultBody = jsonDecode(response.body);
    return PreprocessStatus.fromMap(resultBody);
  }

  static Future<PreprocessStatus> getPreprocessStatus(ApiClient client,
      {required PreprocessStatus preprocessStatus}) async {
    final response = await client.get(
        "/users/${preprocessStatus.ownerId}/records/${preprocessStatus.recordId}/preprocess/${preprocessStatus.id}"
    );
    client.checkResponse(response);
    final body = jsonDecode(response.body);
    return PreprocessStatus.fromMap(body);
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

  static Future<void> upsertRecord(ApiClient client, {required Record record}) async {
    final body = jsonEncode(record.toMap());
    final response = await client.put("/users/${client.userId}/records/${record.id}", body: body);
    client.checkResponse(response);
  }

  static Future<void> uploadAsset(ApiClient client,
      {required AssetUploadData uploadData, required String filename, required ResoniteDBAsset asset, required Uint8List data, void Function(double number)? progressCallback}) async {
    for (int i = 0; i < uploadData.totalChunks; i++) {
      progressCallback?.call(i/uploadData.totalChunks);
      final offset = i * uploadData.chunkSize;
      final end = (i + 1) * uploadData.chunkSize;
      final request = http.MultipartRequest(
        "POST",
        ApiClient.buildFullUri("/users/${client.userId}/assets/${asset.hash}/chunks/$i"),
      )
        ..files.add(http.MultipartFile.fromBytes(
            "file", data.getRange(offset, min(end, data.length)).toList(), filename: filename,
            contentType: MediaType.parse("multipart/form-data")))
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

  static Future<void> uploadAssets(ApiClient client, {required List<AssetDigest> assets, void Function(double progress)? progressCallback}) async {
    progressCallback?.call(0);
    for (int i = 0; i < assets.length; i++) {
      final totalProgress = i/assets.length;
      progressCallback?.call(totalProgress);
      final entry = assets[i];
      final uploadData = await beginUploadAsset(client, asset: entry.asset);
      if (uploadData.uploadState == UploadState.failed) {
        throw "Asset upload failed: ${uploadData.uploadState.name}";
      }
      await uploadAsset(client,
        uploadData: uploadData,
        asset: entry.asset,
        data: entry.data,
        filename: entry.name,
        progressCallback: (progress) => progressCallback?.call(totalProgress + progress * 1/assets.length),
      );
      await finishUpload(client, asset: entry.asset);
    }
    progressCallback?.call(1);
  }

  static Future<Record> uploadImage(ApiClient client, {required File image, required String machineId, void Function(double progress)? progressCallback}) async {
    progressCallback?.call(0);
    final imageDigest = await AssetDigest.fromData(await image.readAsBytes(), basename(image.path));
    final imageData = await decodeImageFromList(imageDigest.data);
    final filename = basenameWithoutExtension(image.path);

    final objectJson = jsonEncode(
        JsonTemplate.image(imageUri: imageDigest.dbUri, filename: filename, width: imageData.width, height: imageData.height).data);
    final objectBytes = Uint8List.fromList(utf8.encode(objectJson));

    final objectDigest = await AssetDigest.fromData(objectBytes, "${basenameWithoutExtension(image.path)}.json");

    final digests = [imageDigest, objectDigest];

    final record = Record.fromRequiredData(
      recordType: RecordType.texture,
      userId: client.userId,
      machineId: machineId,
      assetUri: objectDigest.dbUri,
      filename: filename,
      thumbnailUri: imageDigest.dbUri,
      digests: digests,
      extraTags: ["image"],
    );
    progressCallback?.call(.1);
    final status = await tryPreprocessRecord(client, record: record);
    final toUpload = status.resultDiffs.whereNot((element) => element.isUploaded);
    progressCallback?.call(.2);

    await uploadAssets(
      client,
      assets: digests.where((digest) => toUpload.any((diff) => digest.asset.hash == diff.hash)).toList(),
      progressCallback: (progress) => progressCallback?.call(.2 + progress * .6));
    await upsertRecord(client, record: record);
    progressCallback?.call(1);
    return record;
  }

  static Future<Record> uploadVoiceClip(ApiClient client, {required File voiceClip, required String machineId, void Function(double progress)? progressCallback}) async {
    progressCallback?.call(0);
    final voiceDigest = await AssetDigest.fromData(await voiceClip.readAsBytes(), basename(voiceClip.path));

    final filename = basenameWithoutExtension(voiceClip.path);
    final digests = [voiceDigest];

    final record = Record.fromRequiredData(
      recordType: RecordType.audio,
      userId: client.userId,
      machineId: machineId,
      assetUri: voiceDigest.dbUri,
      filename: filename,
      thumbnailUri: "",
      digests: digests,
      extraTags: ["voice", "message"],
    );
    progressCallback?.call(.1);
    final status = await tryPreprocessRecord(client, record: record);
    final toUpload = status.resultDiffs.whereNot((element) => element.isUploaded);
    progressCallback?.call(.2);

    await uploadAssets(
        client,
        assets: digests.where((digest) => toUpload.any((diff) => digest.asset.hash == diff.hash)).toList(),
        progressCallback: (progress) => progressCallback?.call(.2 + progress * .6));
    await upsertRecord(client, record: record);
    progressCallback?.call(1);
    return record;
  }

  static Future<Record> uploadRawFile(ApiClient client, {required File file, required String machineId, void Function(double progress)? progressCallback}) async {
    progressCallback?.call(0);
    final fileDigest = await AssetDigest.fromData(await file.readAsBytes(), basename(file.path));

    final objectJson = jsonEncode(JsonTemplate.rawFile(assetUri: fileDigest.dbUri, filename: fileDigest.name).data);
    final objectBytes = Uint8List.fromList(utf8.encode(objectJson));

    final objectDigest = await AssetDigest.fromData(objectBytes, "${basenameWithoutExtension(file.path)}.json");

    final digests = [fileDigest, objectDigest];

    final record = Record.fromRequiredData(
      recordType: RecordType.texture,
      userId: client.userId,
      machineId: machineId,
      assetUri: objectDigest.dbUri,
      filename: fileDigest.name,
      thumbnailUri: JsonTemplate.thumbUrl,
      digests: digests,
      extraTags: ["document"],
    );
    progressCallback?.call(.1);
    final status = await tryPreprocessRecord(client, record: record);
    final toUpload = status.resultDiffs.whereNot((element) => element.isUploaded);
    progressCallback?.call(.2);

    await uploadAssets(
        client,
        assets: digests.where((digest) => toUpload.any((diff) => digest.asset.hash == diff.hash)).toList(),
        progressCallback: (progress) => progressCallback?.call(.2 + progress * .6));
    await upsertRecord(client, record: record);
    progressCallback?.call(1);
    return record;
  }
}
