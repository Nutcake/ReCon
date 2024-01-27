import 'dart:convert';

import 'package:recon/clients/api_client.dart';
import 'package:recon/models/users/contact.dart';

class ContactApi {
  static Future<List<Contact>> getFriendsList(ApiClient client, {DateTime? lastStatusUpdate}) async {
    final response = await client.get("/users/${client.userId}/contacts${lastStatusUpdate != null ? "?lastStatusUpdate=${lastStatusUpdate.toUtc().toIso8601String()}" : ""}");
    client.checkResponse(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Contact.fromMap(e)).toList();
  }
}