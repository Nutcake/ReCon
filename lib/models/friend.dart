import 'package:contacts_plus_plus/models/session.dart';
import 'package:contacts_plus_plus/models/user_profile.dart';
import 'package:flutter/material.dart';

class Friend implements Comparable {
  static const _neosBotId = "U-Neos";
  final String id;
  final String username;
  final String ownerId;
  final UserStatus userStatus;
  final UserProfile userProfile;
  final FriendStatus friendStatus;
  final DateTime latestMessageTime;

  Friend({required this.id, required this.username, required this.ownerId, required this.userStatus, required this.userProfile,
    required this.friendStatus, required this.latestMessageTime,
  });

  bool get isHeadless => userStatus.activeSessions.any((session) => session.headlessHost == true && session.hostUserId == id);

  factory Friend.fromMap(Map map) {
    final userStatus = UserStatus.fromMap(map["userStatus"]);
    return Friend(
      id: map["id"],
      username: map["friendUsername"],
      ownerId: map["ownerId"] ?? map["id"],
      // Neos bot status is always offline but should be displayed as online
      userStatus:  map["id"] == _neosBotId ? userStatus.copyWith(onlineStatus: OnlineStatus.online) : userStatus,
      userProfile: UserProfile.fromMap(map["profile"] ?? {}),
      friendStatus: FriendStatus.fromString(map["friendStatus"]),
      latestMessageTime: map["latestMessageTime"] == null
          ? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.parse(map["latestMessageTime"]),
    );
  }

  static Friend? fromMapOrNull(Map? map) {
    if (map == null) return null;
    return Friend.fromMap(map);
  }

  Friend copyWith({
    String? id, String? username, String? ownerId, UserStatus? userStatus, UserProfile? userProfile,
    FriendStatus? friendStatus, DateTime? latestMessageTime}) {
    return Friend(
      id: id ?? this.id,
      username: username ?? this.username,
      ownerId: ownerId ?? this.ownerId,
      userStatus: userStatus ?? this.userStatus,
      userProfile: userProfile ?? this.userProfile,
      friendStatus: friendStatus ?? this.friendStatus,
      latestMessageTime: latestMessageTime ?? this.latestMessageTime,
    );
  }

  Map toMap({bool shallow=false}) {
    return {
      "id": id,
      "username": username,
      "ownerId": ownerId,
      "userStatus": userStatus.toMap(shallow: shallow),
      "profile": userProfile.toMap(),
      "friendStatus": friendStatus.name,
      "latestMessageTime": latestMessageTime.toIso8601String(),
    };
  }

  @override
  int compareTo(covariant Friend other) {
    return username.compareTo(other.username);
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
  offline,
  invisible,
  away,
  busy,
  online;

  static final List<Color> _colors = [
    Colors.white54,
    Colors.white54,
    Colors.yellow,
    Colors.red,
    Colors.green,
  ];

  Color get color => _colors[index];

  factory OnlineStatus.fromString(String? text) {
    return OnlineStatus.values.firstWhere((element) => element.name.toLowerCase() == text?.toLowerCase(),
      orElse: () => OnlineStatus.offline,
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
  final int currentSessionAccessLevel;
  final bool currentSessionHidden;
  final bool currentHosting;
  final Session currentSession;
  final List<Session> activeSessions;
  final String neosVersion;
  final String outputDevice;
  final bool isMobile;
  final String compatibilityHash;

  const UserStatus(
      {required this.onlineStatus, required this.lastStatusChange, required this.currentSession,
        required this.currentSessionAccessLevel, required this.currentSessionHidden, required this.currentHosting,
        required this.activeSessions, required this.neosVersion, required this.outputDevice, required this.isMobile,
        required this.compatibilityHash,
      });

  factory UserStatus.empty() =>
      UserStatus(
        onlineStatus: OnlineStatus.offline,
        lastStatusChange: DateTime.now(),
        currentSessionAccessLevel: 0,
        currentSessionHidden: false,
        currentHosting: false,
        currentSession: Session.none(),
        activeSessions: [],
        neosVersion: "",
        outputDevice: "Unknown",
        isMobile: false,
        compatibilityHash: "",
      );

  factory UserStatus.fromMap(Map map) {
    final statusString = map["onlineStatus"] as String?;
    final status = OnlineStatus.fromString(statusString);
    return UserStatus(
      onlineStatus: status,
      lastStatusChange: DateTime.parse(map["lastStatusChange"]),
      currentSessionAccessLevel: map["currentSessionAccessLevel"] ?? 0,
      currentSessionHidden: map["currentSessionHidden"] ?? false,
      currentHosting: map["currentHosting"] ?? false,
      currentSession: Session.fromMap(map["currentSession"]),
      activeSessions: (map["activeSessions"] as List? ?? []).map((e) => Session.fromMap(e)).toList(),
      neosVersion: map["neosVersion"] ?? "",
      outputDevice: map["outputDevice"] ?? "Unknown",
      isMobile: map["isMobile"] ?? false,
      compatibilityHash: map["compatabilityHash"] ?? ""
    );
  }

  Map toMap({bool shallow = false}) {
    return {
      "onlineStatus": onlineStatus.index,
      "lastStatusChange": lastStatusChange.toIso8601String(),
      "currentSessionAccessLevel": currentSessionAccessLevel,
      "currentSessionHidden": currentSessionHidden,
      "currentHosting": currentHosting,
      "currentSession": currentSession.isNone || shallow ? null : currentSession.toMap(),
      "activeSessions": shallow ? [] : activeSessions.map((e) => e.toMap(),).toList(),
      "neosVersion": neosVersion,
      "outputDevice": outputDevice,
      "isMobile": isMobile,
      "compatibilityHash": compatibilityHash,
    };
  }

  UserStatus copyWith({
    OnlineStatus? onlineStatus,
    DateTime? lastStatusChange,
    int? currentSessionAccessLevel,
    bool? currentSessionHidden,
    bool? currentHosting,
    Session? currentSession,
    List<Session>? activeSessions,
    String? neosVersion,
    String? outputDevice,
    bool? isMobile,
    String? compatibilityHash,
  }) =>
      UserStatus(
        onlineStatus: onlineStatus ?? this.onlineStatus,
        lastStatusChange: lastStatusChange ?? this.lastStatusChange,
        currentSessionAccessLevel: currentSessionAccessLevel ?? this.currentSessionAccessLevel,
        currentSessionHidden: currentSessionHidden ?? this.currentSessionHidden,
        currentHosting: currentHosting ?? this.currentHosting,
        currentSession: currentSession ?? this.currentSession,
        activeSessions: activeSessions ?? this.activeSessions,
        neosVersion: neosVersion ?? this.neosVersion,
        outputDevice: outputDevice ?? this.outputDevice,
        isMobile: isMobile ?? this.isMobile,
        compatibilityHash: compatibilityHash ?? this.compatibilityHash,
      );
}