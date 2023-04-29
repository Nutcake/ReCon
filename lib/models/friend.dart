import 'dart:developer';

import 'package:flutter/foundation.dart';

class Friend extends Comparable {
  final String id;
  final String username;
  final UserStatus userStatus;

  Friend({required this.id, required this.username, required this.userStatus});

  factory Friend.fromMap(Map map) {
    return Friend(id: map["id"], username: map["friendUsername"], userStatus: UserStatus.fromMap(map["userStatus"]));
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

enum OnlineStatus {
  unknown,
  offline,
  away,
  busy,
  online,
}

class UserStatus {
  final OnlineStatus onlineStatus;
  final DateTime lastStatusChange;

  UserStatus({required this.onlineStatus, required this.lastStatusChange});

  factory UserStatus.fromMap(Map map) {
    final statusString = map["onlineStatus"] as String?;
    final status = OnlineStatus.values.firstWhere((element) => element.name.toLowerCase() == statusString?.toLowerCase(),
      orElse: () => OnlineStatus.unknown,
    );
    if (status == OnlineStatus.unknown && statusString != null) {
      log("Unknown OnlineStatus '$statusString' in response");
    }
    return UserStatus(
      onlineStatus: status,
      lastStatusChange: DateTime.parse(map["lastStatusChange"]),
    );
  }
}