import 'dart:convert';

import 'package:contacts_plus/api_client.dart';
import 'package:contacts_plus/models/message.dart';

class MessageApi extends BaseClient {
  static Future<Iterable<Message>> getUserMessages({String userId="", DateTime? fromTime, int maxItems=50, bool unreadOnly=false}) async {
    final response = await BaseClient.client.get("/users/${BaseClient.client.userId}/messages"
        "?maxItems=$maxItems"
        "${fromTime == null ? "" : "&fromTime${fromTime.toLocal().toIso8601String()}"}"
        "${userId.isEmpty ? "" : "&user=$userId"}"
        "&unread=$unreadOnly"
    );
    ApiClient.checkResponse(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Message.fromMap(e));
  }
}