import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:contacts_plus_plus/models/records/image_template.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/models/records/asset_upload_data.dart';
import 'package:contacts_plus_plus/models/records/neos_db_asset.dart';
import 'package:contacts_plus_plus/models/records/preprocess_status.dart';
import 'package:contacts_plus_plus/models/records/record.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

class RecordApi {
  static Future<List<Record>> getRecordsAt(ApiClient client, {required String path}) async {
    final response = await client.get("/users/${client.userId}/records?path=$path");
    ApiClient.checkResponse(response);
    final body = jsonDecode(response.body) as List;
    return body.map((e) => Record.fromMap(e)).toList();
  }

  static Future<PreprocessStatus> preprocessRecord(ApiClient client, {required Record record}) async {
    final body = jsonEncode(record.toMap());
    final response = await client.post(
        "/users/${record.ownerId}/records/${record.id}/preprocess", body: body);
    ApiClient.checkResponse(response);
    final resultBody = jsonDecode(response.body);
    return PreprocessStatus.fromMap(resultBody);
  }

  static Future<PreprocessStatus> getPreprocessStatus(ApiClient client,
      {required PreprocessStatus preprocessStatus}) async {
    final response = await client.get(
        "/users/${preprocessStatus.ownerId}/records/${preprocessStatus.recordId}/preprocess/${preprocessStatus.id}"
    );
    ApiClient.checkResponse(response);
    final body = jsonDecode(response.body);
    return PreprocessStatus.fromMap(body);
  }

  static Future<AssetUploadData> beginUploadAsset(ApiClient client, {required NeosDBAsset asset}) async {
    final response = await client.post("/users/${client.userId}/assets/${asset.hash}/chunks");
    ApiClient.checkResponse(response);
    final body = jsonDecode(response.body);
    final res = AssetUploadData.fromMap(body);
    if (res.uploadState == UploadState.failed) throw body;
    return res;
  }

  static Future<void> upsertRecord(ApiClient client, {required Record record}) async {
    final body = jsonEncode(record.toMap());
    final response = await client.put("/users/${client.userId}/records/${record.id}", body: body);
    ApiClient.checkResponse(response);
  }

  static Future<void> uploadAsset(ApiClient client, {required AssetUploadData uploadData, required String filename, required NeosDBAsset asset, required Uint8List data}) async {
    for (int i = 0; i < uploadData.totalChunks; i++) {
      final offset = i*uploadData.chunkSize;
      final end = (i+1)*uploadData.chunkSize;
      final request = http.MultipartRequest(
        "POST",
        ApiClient.buildFullUri("/users/${client.userId}/assets/${asset.hash}/chunks/$i"),
      )..files.add(http.MultipartFile.fromBytes("file", data.getRange(offset, min(end, data.length)).toList(), filename: filename, contentType: MediaType.parse("multipart/form-data")))
        ..headers.addAll(client.authorizationHeader);
      final response = await request.send();
      final bodyBytes = await response.stream.toBytes();
      ApiClient.checkResponse(http.Response.bytes(bodyBytes, response.statusCode));
    }
  }

  static Future<void> finishUpload(ApiClient client, {required NeosDBAsset asset}) async {
    final response = await client.patch("/users/${client.userId}/assets/${asset.hash}/chunks");
    ApiClient.checkResponse(response);
  }

  static Future<Record> uploadImage(ApiClient client, {required File image, required String machineId}) async {
    final imageData = await image.readAsBytes();
    final imageImage = await decodeImageFromList(imageData);
    final imageAsset = NeosDBAsset.fromData(imageData);
    final imageNeosDbUri = "neosdb:///${imageAsset.hash}${extension(image.path)}";
    final objectJson = jsonEncode(ImageTemplate(imageUri: imageNeosDbUri, width: imageImage.width, height: imageImage.height).data);
    final objectBytes = Uint8List.fromList(utf8.encode(objectJson));
    final objectAsset = NeosDBAsset.fromData(objectBytes);
    final objectNeosDbUri = "neosdb:///${objectAsset.hash}.json";
    final combinedRecordId = RecordId(id: Record.generateId(), ownerId: client.userId, isValid: true);
    final filename = basenameWithoutExtension(image.path);
    final record = Record(
      id: combinedRecordId.id.toString(),
      combinedRecordId: combinedRecordId,
      assetUri: objectNeosDbUri,
      name: filename,
      tags: [
        filename,
        "message_item",
        "message_id:${Message.generateId()}"
      ],
      recordType: RecordType.texture,
      thumbnailUri: imageNeosDbUri,
      isPublic: false,
      isForPatreons: false,
      isListed: false,
      neosDBManifest: [
        imageAsset,
        objectAsset,
      ],
      globalVersion: 0,
      localVersion: 1,
      lastModifyingUserId: client.userId,
      lastModifyingMachineId: machineId,
      lastModificationTime: DateTime.now().toUtc(),
      creationTime: DateTime.now().toUtc(),
      ownerId: client.userId,
      isSynced: false,
      fetchedOn: DateTimeX.one,
      path: '',
      description: '',
      manifest: [
        imageNeosDbUri,
        objectNeosDbUri
      ],
      url: "neosrec:///${client.userId}/${combinedRecordId.id}",
      isValidOwnerId: true,
      isValidRecordId: true,
      visits: 0,
      rating: 0,
      randomOrder: 0,
    );

    var status = await preprocessRecord(client, record: record);
    while (status.state == RecordPreprocessState.preprocessing) {
      await Future.delayed(const Duration(seconds: 1));
      status = await getPreprocessStatus(client, preprocessStatus: status);
    }

    if (status.state != RecordPreprocessState.success) {
      throw "Record Preprocessing failed: ${status.failReason}";
    }
    AssetUploadData uploadData;
    if ((status.resultDiffs.firstWhereOrNull((element) => element.hash == imageAsset.hash)?.isUploaded ?? false) == false) {
      uploadData = await beginUploadAsset(client, asset: imageAsset);
      if (uploadData.uploadState == UploadState.failed) {
        throw "Asset upload failed: ${uploadData.uploadState.name}";
      }

      await uploadAsset(client, uploadData: uploadData, asset: imageAsset, data: imageData, filename: filename);
      await finishUpload(client, asset: imageAsset);
    }

    uploadData = await beginUploadAsset(client, asset: objectAsset);
    if (uploadData.uploadState == UploadState.failed) {
      throw "Asset upload failed: ${uploadData.uploadState.name}";
    }

    await uploadAsset(client, uploadData: uploadData, asset: objectAsset, data: objectBytes, filename: filename);
    await finishUpload(client, asset: objectAsset);

    return record;
  }
}