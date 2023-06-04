import 'dart:convert';

import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/models/cloud_variable.dart';

class CloudVariableApi {
  static Future<CloudVariable> readCloudVariable(ApiClient client,
      {required String ownerId, required String path,}) async {
    final response = await client.get("/${ownerId.isEmpty ? "globalvars" : "users/$ownerId/vars"}/$path");
    client.checkResponse(response);
    final body = jsonDecode(response.body);
    return CloudVariable.fromMap(body);
  }

  static Future<CloudVariable> readGlobalCloudVariable(ApiClient client, {required String path}) async =>
      await readCloudVariable(client, ownerId: "", path: path);

  static Future<void> deleteCloudVariable(ApiClient client, {required String ownerId, required String path}) async {
    final response = await client.delete("/users/vars/$path");
    client.checkResponse(response);
  }

  static Future<void> writeCloudVariable(ApiClient client, {required String ownerId, required String path, required String value}) async {
    final response = await client.put("/users/$ownerId/vars/$path", body: value);
    client.checkResponse(response);
  }
}
