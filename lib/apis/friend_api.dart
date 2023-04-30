
import 'dart:convert';

import 'package:contacts_plus/api_client.dart';
import 'package:contacts_plus/models/friend.dart';

class FriendApi {
  static Future<Iterable<Friend>> getFriendsList(ApiClient client) async {
    final response = await client.get("/users/${client.userId}/friends");
    ApiClient.checkResponse(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Friend.fromMap(e));
  }
}