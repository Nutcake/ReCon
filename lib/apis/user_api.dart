import 'dart:convert';

import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/models/friend.dart';
import 'package:contacts_plus_plus/models/personal_profile.dart';
import 'package:contacts_plus_plus/models/user.dart';
import 'package:contacts_plus_plus/models/user_profile.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UserApi {
  static Future<Iterable<User>> searchUsers(ApiClient client, {required String needle}) async {
    final response = await client.get("/users?name=$needle");
    ApiClient.checkResponse(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => User.fromMap(e));
  }
  
  static Future<User> getUser(ApiClient client, {required String userId}) async {
    final response = await client.get("/users/$userId/");
    ApiClient.checkResponse(response);
    final data = jsonDecode(response.body);
    return User.fromMap(data);
  }

  static Future<UserStatus> getUserStatus(ApiClient client, {required String userId}) async {
    final response = await client.get("/users/$userId/status");
    ApiClient.checkResponse(response);
    final data = jsonDecode(response.body);
    return UserStatus.fromMap(data);
  }
  
  static Future<void> notifyOnlineInstance(ApiClient client, {required String machineId}) async {
    final response = await client.post("/stats/instanceOnline/$machineId");
    ApiClient.checkResponse(response);
  }

  static Future<void> setStatus(ApiClient client, {required UserStatus status}) async {
    final pkginfo = await PackageInfo.fromPlatform();
    status = status.copyWith(
      neosVersion: "${pkginfo.version} of ${pkginfo.appName}",
    );
    final body = jsonEncode(status.toMap(shallow: true));
    final response = await client.put("/users/${client.userId}/status", body: body);
    ApiClient.checkResponse(response);
  }

  static Future<PersonalProfile> getPersonalProfile(ApiClient client) async {
    final response = await client.get("/users/${client.userId}");
    ApiClient.checkResponse(response);
    final data = jsonDecode(response.body);
    return PersonalProfile.fromMap(data);
  }

  static Future<void> addUserAsFriend(ApiClient client, {required User user}) async {
    final friend = Friend(
      id: user.id,
      username: user.username,
      ownerId: client.userId,
      userStatus: UserStatus.empty(),
      userProfile: UserProfile.empty(),
      friendStatus: FriendStatus.accepted,
      latestMessageTime: DateTime.now(),
    );
    final body = jsonEncode(friend.toMap(shallow: true));
    final response = await client.put("/users/${client.userId}/friends/${user.id}", body: body);
    ApiClient.checkResponse(response);
  }

  static Future<void> removeUserAsFriend(ApiClient client, {required User user}) async {
    final response = await client.delete("/users/${client.userId}/friends/${user.id}");
    ApiClient.checkResponse(response);
  }
}