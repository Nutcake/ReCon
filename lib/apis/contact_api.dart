import 'dart:convert';

import 'package:recon/clients/api_client.dart';
import 'package:recon/models/users/friend.dart';

class ContactApi {
  static Future<List<Friend>> getFriendsList(ApiClient client, {DateTime? lastStatusUpdate}) async {
    final response = await client.get("/users/${client.userId}/contacts${lastStatusUpdate != null ? "?lastStatusUpdate=${lastStatusUpdate.toUtc().toIso8601String()}" : ""}");
    client.checkResponse(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Friend.fromMap(e)).toList();
  }
}
