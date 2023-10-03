import 'dart:convert';

import 'package:recon/clients/api_client.dart';
import 'package:recon/models/session.dart';

class SessionApi {
  static Future<Session> getSession(ApiClient client, {required String sessionId}) async {
    final response = await client.get("/sessions/$sessionId");
    client.checkResponse(response);
    final body = jsonDecode(response.body);
    return Session.fromMap(body);
  }

  static Future<List<Session>> getSessions(ApiClient client, {SessionFilterSettings? filterSettings}) async {
    final response = await client.get("/sessions${filterSettings == null ? "" : filterSettings.buildRequestString()}");
    client.checkResponse(response);
    final body = jsonDecode(response.body) as List;
    return body.map((e) => Session.fromMap(e)).toList();
  }
}