import 'dart:developer';

import 'package:contacts_plus/models/user_profile.dart';

class Friend extends Comparable {
  final String id;
  final String username;
  final UserStatus userStatus;
  final UserProfile userProfile;
  final FriendStatus friendStatus;

  Friend({required this.id, required this.username, required this.userStatus, required this.userProfile,
    required this.friendStatus,
  });

  factory Friend.fromMap(Map map) {
    return Friend(
      id: map["id"],
      username: map["friendUsername"],
      userStatus: UserStatus.fromMap(map["userStatus"]),
      userProfile: UserProfile.fromMap(map["profile"] ?? {}),
      friendStatus: FriendStatus.fromString(map["friendStatus"]),
    );
  }

  @override
  int compareTo(other) {
    if (userStatus.onlineStatus == other.userStatus.onlineStatus) {
      return userStatus.lastStatusChange.compareTo(other.userStatus.lastStatusChange);
    } else {
      if (userStatus.onlineStatus == OnlineStatus.online) {
        return -1;
      } else {
        return 1;
      }
    }
  }
}

class Session {
  final String id;
  final String name;
  final List<SessionUser> sessionUsers;
  final String thumbnail;
  
  Session({required this.id, required this.name, required this.sessionUsers, required this.thumbnail});
  
  factory Session.fromMap(Map map) {
    return Session(
      id: map["sessionId"],
      name: map["name"],
      sessionUsers: (map["sessionUsers"] as List? ?? []).map((entry) => SessionUser.fromMap(entry)).toList(),
      thumbnail: map["thumbnail"]
    );
  }
}

class SessionUser {
  final String id;
  final String username;
  final bool isPresent;
  final int outputDevice;

  SessionUser({required this.id, required this.username, required this.isPresent, required this.outputDevice});

  factory SessionUser.fromMap(Map map) {
    return SessionUser(
      id: map["userID"],
      username: map["username"],
      isPresent: map["isPresent"],
      outputDevice: map["outputDevice"],
    );
  }
}

enum FriendStatus {
  none,
  searchResult,
  requested,
  ignored,
  blocked,
  accepted;

  factory FriendStatus.fromString(String text) {
    return FriendStatus.values.firstWhere((element) => element.name.toLowerCase() == text.toLowerCase(),
      orElse: () => FriendStatus.none,
    );
  }
}

enum OnlineStatus {
  unknown,
  offline,
  away,
  busy,
  online;

  factory OnlineStatus.fromString(String? text) {
    return OnlineStatus.values.firstWhere((element) => element.name.toLowerCase() == text?.toLowerCase(),
      orElse: () => OnlineStatus.unknown,
    );
  }
}

class UserStatus {
  final OnlineStatus onlineStatus;
  final DateTime lastStatusChange;
  final List<Session> activeSessions;


  UserStatus({required this.onlineStatus, required this.lastStatusChange, required this.activeSessions});

  factory UserStatus.fromMap(Map map) {
    final statusString = map["onlineStatus"] as String?;
    final status = OnlineStatus.fromString(statusString);
    if (status == OnlineStatus.unknown && statusString != null) {
      log("Unknown OnlineStatus '$statusString' in response");
    }
    return UserStatus(
      onlineStatus: status,
      lastStatusChange: DateTime.parse(map["lastStatusChange"]),
      activeSessions: (map["activeSessions"] as List? ?? []).map((e) => Session.fromMap(e)).toList(),
    );
  }
}