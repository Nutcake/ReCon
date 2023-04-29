
import 'dart:convert';

import 'package:contacts_plus/api_client.dart';
import 'package:contacts_plus/models/friend.dart';

class FriendApi {

  const FriendApi({required apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Iterable<Friend>> getFriendsList() async {
    final response = await _apiClient.get("/users/${_apiClient.userId}/friends");
    ApiClient.checkResponse(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Friend.fromMap(e));
  }
}