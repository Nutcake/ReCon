
import 'dart:convert';

import 'package:contacts_plus/api_client.dart';
import 'package:contacts_plus/models/friend.dart';
import 'package:contacts_plus/models/user.dart';

class FriendApi {
  static Future<Iterable<Friend>> getFriendsList(ApiClient client) async {
    final response = await client.get("/users/${client.userId}/friends");
    ApiClient.checkResponse(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Friend.fromMap(e));
  }

  static Future<void> addFriend(ApiClient client, {required User user}) async {
    final response = await client.put("/users/${client.userId}/friends/${user.id}", body: user.toMap());
    ApiClient.checkResponse(response);
  }
}