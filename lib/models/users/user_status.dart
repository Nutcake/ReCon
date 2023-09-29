import 'package:contacts_plus_plus/config.dart';
import 'package:contacts_plus_plus/models/session.dart';
import 'package:contacts_plus_plus/models/users/online_status.dart';

class UserStatus {
  final OnlineStatus onlineStatus;
  final DateTime lastStatusChange;
  final int currentSessionAccessLevel;
  final bool currentSessionHidden;
  final bool currentHosting;
  final Session currentSession;
  final List<Session> activeSessions;
  final String appVersion;
  final String outputDevice;
  final bool isMobile;
  final String compatibilityHash;

  const UserStatus({
    required this.onlineStatus,
    required this.lastStatusChange,
    required this.currentSession,
    required this.currentSessionAccessLevel,
    required this.currentSessionHidden,
    required this.currentHosting,
    required this.activeSessions,
    required this.appVersion,
    required this.outputDevice,
    required this.isMobile,
    required this.compatibilityHash,
  });

  factory UserStatus.empty() => UserStatus(
        onlineStatus: OnlineStatus.offline,
        lastStatusChange: DateTime.now(),
        currentSessionAccessLevel: 0,
        currentSessionHidden: false,
        currentHosting: false,
        currentSession: Session.none(),
        activeSessions: [],
        appVersion: "",
        outputDevice: "Unknown",
        isMobile: false,
        compatibilityHash: "",
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
        currentSession: Session.fromMap(map["currentSession"]),
        activeSessions: (map["activeSessions"] as List? ?? []).map((e) => Session.fromMap(e)).toList(),
        appVersion: map["appVersion"] ?? "",
        outputDevice: map["outputDevice"] ?? "Unknown",
        isMobile: map["isMobile"] ?? false,
        compatibilityHash: map["compatabilityHash"] ?? "");
  }

  Map toMap({bool shallow = false}) {
    return {
      "onlineStatus": onlineStatus.index,
      "lastStatusChange": lastStatusChange.toIso8601String(),
      "currentSessionAccessLevel": currentSessionAccessLevel,
      "currentSessionHidden": currentSessionHidden,
      "currentHosting": currentHosting,
      "currentSession": currentSession.isNone || shallow ? null : currentSession.toMap(),
      "activeSessions": shallow
          ? []
          : activeSessions
              .map(
                (e) => e.toMap(),
              )
              .toList(),
      "neosVersion": appVersion,
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
        appVersion: neosVersion ?? this.appVersion,
        outputDevice: outputDevice ?? this.outputDevice,
        isMobile: isMobile ?? this.isMobile,
        compatibilityHash: compatibilityHash ?? this.compatibilityHash,
      );
}
