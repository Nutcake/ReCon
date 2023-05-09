
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:contacts_plus_plus/models/message.dart';
import 'package:http/http.dart' as http;

import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/models/asset/asset_upload_data.dart';
import 'package:contacts_plus_plus/models/asset/neos_db_asset.dart';
import 'package:contacts_plus_plus/models/asset/preprocess_status.dart';
import 'package:contacts_plus_plus/models/asset/record.dart';
import 'package:path/path.dart';

class AssetApi {
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

  static Future<String> uploadAssets(ApiClient client, {required NeosDBAsset asset, required Uint8List data}) async {
    final request = http.MultipartRequest(
      "POST",
      ApiClient.buildFullUri("/users/${client.userId}/assets/${asset.hash}"),
    )
      ..files.add(http.MultipartFile.fromBytes("file", data));
    final response = await request.send();
    final body = jsonDecode(await response.stream.bytesToString());
    return body;
  }

  static Future<Record> uploadFile(ApiClient client, {required File file, required String machineId}) async {
    final data = await file.readAsBytes();
    final asset = NeosDBAsset.fromData(data);
    final assetUri = "local://$machineId/${asset.hash}${extension(file.path)}";
    final record = Record(
      id: Record.generateId(),
      assetUri: assetUri,
      name: basenameWithoutExtension(file.path),
      tags: [
        "message_item",
        "message_id:${Message.generateId()}"
      ],
      recordType: "texture",
      thumbnailUri: assetUri,
      isPublic: false,
      isForPatreons: false,
      isListed: false,
      isDeleted: false,
      neosDBManifest: [
        asset,
      ],
      localVersion: 1,
      lastModifyingUserId: client.userId,
      lastModifyingMachineId: machineId,
      lastModificationTime: DateTime.now().toUtc(),
      creationTime: DateTime.now().toUtc(),
      ownerId: client.userId,
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

    await uploadAssets(client, asset: asset, data: data);
    return record;
  }
}