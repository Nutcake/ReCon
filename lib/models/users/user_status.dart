import 'dart:convert';

import 'package:contacts_plus_plus/crypto_helper.dart';
import 'package:contacts_plus_plus/models/session_metadata.dart';
import 'package:contacts_plus_plus/models/users/online_status.dart';
import 'package:crypto/crypto.dart';

class UserStatus {
  final OnlineStatus onlineStatus;
  final DateTime lastStatusChange;
  final int currentSessionAccessLevel;
  final bool currentSessionHidden;
  final bool currentHosting;
  final int currentSessionIndex;
  final List<SessionMetadata> sessions;
  final String appVersion;
  final String outputDevice;
  final bool isMobile;
  final String compatibilityHash;
  final String hashSalt;

  const UserStatus({
    required this.onlineStatus,
    required this.lastStatusChange,
    required this.currentSessionIndex,
    required this.currentSessionAccessLevel,
    required this.currentSessionHidden,
    required this.currentHosting,
    required this.sessions,
    required this.appVersion,
    required this.outputDevice,
    required this.isMobile,
    required this.compatibilityHash,
    required this.hashSalt,
  });

  factory UserStatus.initial() => UserStatus.empty().copyWith(
        onlineStatus: OnlineStatus.online,
        hashSalt: CryptoHelper.cryptoToken(),
        outputDevice: "Mobile",
      );

  factory UserStatus.empty() => UserStatus(
        onlineStatus: OnlineStatus.offline,
        lastStatusChange: DateTime.now(),
        currentSessionAccessLevel: 0,
        currentSessionHidden: false,
        currentHosting: false,
        currentSessionIndex: -1,
        sessions: [],
        appVersion: "",
        outputDevice: "Unknown",
        isMobile: false,
        compatibilityHash: "",
        hashSalt: "",
      );

  factory UserStatus.fromMap(Map map) {
    final statusString = map["onlineStatus"].toString();
    final status = OnlineStatus.fromString(statusString);
    return UserStatus(
      onlineStatus: status,
      lastStatusChange: DateTime.parse(map["lastStatusChange"]),
      currentSessionAccessLevel: map["currentSessionAccessLevel"] ?? 0,
      currentSessionHidden: map["currentSessionHidden"] ?? false,
      currentHosting: map["currentHosting"] ?? false,
      currentSessionIndex: map["currentSessionIndex"] ?? -1,
      sessions: (map["sessions"] as List? ?? []).map((e) => SessionMetadata.fromMap(e)).toList(),
      appVersion: map["appVersion"] ?? "",
      outputDevice: map["outputDevice"] ?? "Unknown",
      isMobile: map["isMobile"] ?? false,
      compatibilityHash: map["compatabilityHash"] ?? "",
      hashSalt: map["hashSalt"] ?? "",
    );
  }

  Map toMap({bool shallow = false}) {
    return {
      "onlineStatus": onlineStatus.index,
      "lastStatusChange": lastStatusChange.toIso8601String(),
      "currentSessionAccessLevel": currentSessionAccessLevel,
      "currentSessionHidden": currentSessionHidden,
      "currentHosting": currentHosting,
      "currentSessionIndex": currentSessionIndex,
      "sessions": shallow
          ? []
          : sessions
              .map(
                (e) => e.toMap(),
              )
              .toList(),
      "appVersion": appVersion,
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
    int? currentSessionIndex,
    List<SessionMetadata>? sessions,
    String? appVersion,
    String? outputDevice,
    bool? isMobile,
    String? compatibilityHash,
    String? hashSalt,
  }) =>
      UserStatus(
        onlineStatus: onlineStatus ?? this.onlineStatus,
        lastStatusChange: lastStatusChange ?? this.lastStatusChange,
        currentSessionAccessLevel: currentSessionAccessLevel ?? this.currentSessionAccessLevel,
        currentSessionHidden: currentSessionHidden ?? this.currentSessionHidden,
        currentHosting: currentHosting ?? this.currentHosting,
        currentSessionIndex: currentSessionIndex ?? this.currentSessionIndex,
        sessions: sessions ?? this.sessions,
        appVersion: appVersion ?? this.appVersion,
        outputDevice: outputDevice ?? this.outputDevice,
        isMobile: isMobile ?? this.isMobile,
        compatibilityHash: compatibilityHash ?? this.compatibilityHash,
        hashSalt: hashSalt ?? this.hashSalt,
      );
}
