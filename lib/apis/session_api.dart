import 'dart:convert';

import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/models/session.dart';

class SessionApi {
  static Future<Session> getSession(ApiClient client, {required String sessionId}) async {
    final response = await client.get("/sessions/$sessionId");
    client.checkResponse(response);
    final body = jsonDecode(response.body);
    return Session.fromMap(body);
  }
}