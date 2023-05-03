import 'dart:developer';

import 'package:contacts_plus_plus/models/session.dart';
import 'package:contacts_plus_plus/models/user_profile.dart';

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

  int compareTo(OnlineStatus other) {
    if (this == other) return 0;
    if (this == OnlineStatus.online) return -1;
    if (other == OnlineStatus.online) return 1;
    if (this == OnlineStatus.away) return -1;
    if (other == OnlineStatus.away) return 1;
    if (this == OnlineStatus.busy) return -1;
    if (other == OnlineStatus.busy) return 1;
    return 0;
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