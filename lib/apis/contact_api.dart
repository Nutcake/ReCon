import 'dart:convert';

import 'package:recon/clients/api_client.dart';
import 'package:recon/models/users/contact.dart';
import 'package:recon/models/users/contact_status.dart';
import 'package:recon/models/users/user.dart';
import 'package:recon/models/users/user_profile.dart';
import 'package:recon/models/users/user_status.dart';

class ContactApi {
  static Future<List<Contact>> getFriendsList(ApiClient client, {DateTime? lastStatusUpdate}) async {
    final response = await client.get("/users/${client.userId}/contacts${lastStatusUpdate != null ? "?lastStatusUpdate=${lastStatusUpdate.toUtc().toIso8601String()}" : ""}");
    client.checkResponse(response);
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Contact.fromMap(e)).toList();
  }

  static Future<void> addUserAsFriend(ApiClient client, {required User user}) async {
    final friend = Contact(
      id: user.id,
      contactUsername: user.username,
      ownerId: client.userId,
      userStatus: UserStatus.empty(),
      userProfile: UserProfile.empty(),
      friendStatus: ContactStatus.accepted,
      latestMessageTime: DateTime.now(),
    );
    final body = jsonEncode(friend.toMap(shallow: true));
    final response = await client.put("/users/${client.userId}/contacts/${user.id}", body: body);
    client.checkResponse(response);
  }

  static Future<void> removeUserAsFriend(ApiClient client, {required User user}) async {
    final response = await client.delete("/users/${client.userId}/friends/${user.id}");
    client.checkResponse(response);
  }
}