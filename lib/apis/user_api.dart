import 'dart:convert';

import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/models/friend.dart';
import 'package:contacts_plus_plus/models/user.dart';
import 'package:contacts_plus_plus/models/user_profile.dart';

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

  static Future<void> addUserAsFriend(ApiClient client, {required User user}) async {
    final friend = Friend(
      id: user.id,
      username: user.username,
      ownerId: client.userId,
      userStatus: UserStatus.empty(),
      userProfile: UserProfile.empty(),
      friendStatus: FriendStatus.accepted,
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