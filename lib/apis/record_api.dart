
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:http/http.dart' as http;

import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/models/records/asset_upload_data.dart';
import 'package:contacts_plus_plus/models/records/neos_db_asset.dart';
import 'package:contacts_plus_plus/models/records/preprocess_status.dart';
import 'package:contacts_plus_plus/models/records/record.dart';
import 'package:path/path.dart';

class AssetApi {
  static Future<List<Record>> getRecordsAt(ApiClient client, {required String path}) async {
    final response = await client.get("/users/${client.userId}/records?path=$path");
    ApiClient.checkResponse(response);
    final body = jsonDecode(response.body) as List;
    return body.map((e) => Record.fromMap(e)).toList();
  }

  static Future<PreprocessStatus> preprocessRecord(ApiClient client, {required Record record}) async {
    final response = await client.post(
        "/users/${record.ownerId}/records/${record.id}/preprocess", body: jsonEncode(record.toMap()));
    ApiClient.checkResponse(response);
    final body = jsonDecode(response.body);
    return PreprocessStatus.fromMap(body);
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
    final response = await client.post("/users/${client.userId}/assets/${asset.hash}/chunks?bytes=${asset.bytes}");
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

  static Future<String> uploadAsset(ApiClient client, {required NeosDBAsset asset, required Uint8List data}) async {
    final request = http.MultipartRequest(
      "POST",
      ApiClient.buildFullUri("/users/${client.userId}/assets/${asset.hash}"),
    )
      ..files.add(http.MultipartFile.fromBytes("file", data));
    final response = await request.send();
    final body = jsonDecode(await response.stream.bytesToString());
    return body;
  }

  static Future<void> finishUpload(ApiClient client, {required NeosDBAsset asset}) async {
    final response = await client.patch("/users/${client.userId}/assets/${asset.hash}/chunks");
    ApiClient.checkResponse(response);
  }

  static Future<Record> uploadFile(ApiClient client, {required File file, required String machineId}) async {
    final data = await file.readAsBytes();
    final asset = NeosDBAsset.fromData(data);
    final assetUri = "neosdb://$machineId/${asset.hash}${extension(file.path)}";
    final combinedRecordId = RecordId(id: Record.generateId(), ownerId: client.userId, isValid: true);
    final record = Record(
      id: 0,
      recordId: combinedRecordId.id.toString(),
      combinedRecordId: combinedRecordId,
      assetUri: assetUri,
      name: basenameWithoutExtension(file.path),
      tags: [
        "message_item",
        "message_id:${Message.generateId()}"
      ],
      recordType: RecordType.texture,
      thumbnailUri: assetUri,
      isPublic: false,
      isForPatreons: false,
      isListed: false,
      neosDBManifest: [
        asset,
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
        assetUri
      ],
      url: "neosrec://${client.userId}/${combinedRecordId.id}",
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

    final uploadData = await beginUploadAsset(client, asset: asset);
    if (uploadData.uploadState == UploadState.failed) {
      throw "Asset upload failed: ${uploadData.uploadState.name}";
    }

    await uploadAsset(client, asset: asset, data: data);
    await finishUpload(client, asset: asset);
    return record;
  }
}