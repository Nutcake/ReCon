
import 'dart:convert';

import 'package:contacts_plus/api_client.dart';
import 'package:contacts_plus/models/friend.dart';

class FriendApi extends BaseClient {
  static Future<Iterable<Friend>> getFriendsList() async {
    final response = await BaseClient.client.get("/users/${BaseClient.client.userId}/friends");
    ApiClient.checkResponse(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Friend.fromMap(e));
  }
}