
import 'dart:convert';

import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/models/session.dart';

class SessionApi {
  static Future<List<Session>> getSessions(ApiClient client, {DateTime? updatedSince, bool includeEnded = false,
    String name = "", String hostName = "", String hostId = "", int minActiveUsers = 0, bool includeEmptyHeadless = true,
  }) async {
    final query = "?includeEnded=$includeEnded"
        "&includeEmptyHeadless=$includeEmptyHeadless"
        "&minActiveUsers=$minActiveUsers"
        "${updatedSince == null ? "" : "&updatedSince=${updatedSince.toIso8601String()}"}"
        "${name.isEmpty ? "" : "&name=$name"}"
        "${hostName.isEmpty ? "" : "&hostName=$hostName"}"
        "${hostId.isEmpty ? "" : "&hostId=$hostId"}";
    final response = await client.get("/sessions$query");
    ApiClient.checkResponse(response);
    final body = jsonDecode(response.body) as List;
    return body.map((e) => Session.fromMap(e)).toList();
  }
}