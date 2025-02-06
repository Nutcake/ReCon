import 'dart:convert';

import 'package:recon/clients/api_client.dart';
import 'package:recon/models/message.dart';

class MessageApi {
  static Future<List<Message>> getUserMessages(
    ApiClient client, {
    String userId = "",
    DateTime? fromTime,
    int maxItems = 50,
    bool unreadOnly = false,
  }) async {
    final response = await client.get("/users/${client.userId}/messages"
        "?maxItems=$maxItems"
        "${fromTime == null ? "" : "&fromTime${fromTime.toLocal().toIso8601String()}"}"
        "${userId.isEmpty ? "" : "&user=$userId"}"
        "&unread=$unreadOnly");
    client.checkResponse(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Message.fromMap(e)).toList();
  }
}
