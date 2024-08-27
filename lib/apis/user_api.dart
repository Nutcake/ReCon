import 'dart:convert';

import 'package:recon/clients/api_client.dart';
import 'package:recon/models/personal_profile.dart';
import 'package:recon/models/users/user.dart';
import 'package:recon/models/users/user_status.dart';

class UserApi {
  static Future<Iterable<User>> searchUsers(ApiClient client, {required String needle}) async {
    final response = await client.get("/users?name=$needle");
    client.checkResponse(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => User.fromMap(e));
  }

  static Future<User> getUser(ApiClient client, {required String userId}) async {
    final response = await client.get("/users/$userId/");
    client.checkResponse(response);
    final data = jsonDecode(response.body);
    return User.fromMap(data);
  }

  static Future<UserStatus> getUserStatus(ApiClient client, {required String userId}) async {
    final response = await client.get("/users/$userId/status");
    client.checkResponse(response);
    final data = jsonDecode(response.body);
    return UserStatus.fromMap(data);
  }

  static Future<void> notifyOnlineInstance(ApiClient client) async {
    final response = await client.post("/stats/instanceOnline/${client.authenticationData.secretMachineIdHash}");
    client.checkResponse(response);
  }

  static Future<PersonalProfile> getPersonalProfile(ApiClient client) async {
    final response = await client.get("/users/${client.userId}");
    client.checkResponse(response);
    final data = jsonDecode(response.body);
    return PersonalProfile.fromMap(data);
  }

  static Future<StorageQuota> getStorageQuota(ApiClient client) async {
    final response = await client.get("/users/${client.userId}/storage");
    client.checkResponse(response);
    final data = jsonDecode(response.body);
    return StorageQuota.fromMap(data);
  }
}
