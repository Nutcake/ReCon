import 'package:intl/intl.dart';
import 'package:recon/config.dart';
import 'package:recon/crypto_helper.dart';
import 'package:recon/models/session.dart';
import 'package:recon/models/session_metadata.dart';
import 'package:recon/models/users/online_status.dart';
import 'package:uuid/uuid.dart';

enum UserSessionType
{
  unknown,
  graphicalClient,
  chatClient,
  headless,
  bot;

  factory UserSessionType.fromString(String? text) {
    return UserSessionType.values.firstWhere((element) => element.name.toLowerCase() == text?.toLowerCase(),
      orElse: () => UserSessionType.unknown,
    );
  }
}

class UserStatus {
  static const statusExpiration = const Duration(minutes: 5);
  final String userId;
  final OnlineStatus onlineStatus;
  final DateTime lastStatusChange;
  final DateTime lastPresenceTimestamp;
  final String userSessionId;
  final int currentSessionIndex;
  final List<SessionMetadata> sessions;
  final String appVersion;
  final String? outputDevice;
  final bool isMobile;
  final bool isPresent;
  final String compatibilityHash;
  final String hashSalt;
  final UserSessionType sessionType;
  final List<Session> decodedSessions;

  const UserStatus({
    required this.userId,
    required this.onlineStatus,
    required this.lastStatusChange,
    required this.lastPresenceTimestamp,
    required this.userSessionId,
    required this.currentSessionIndex,
    required this.sessions,
    required this.appVersion,
    required this.outputDevice,
    required this.isMobile,
    required this.isPresent,
    required this.compatibilityHash,
    required this.hashSalt,
    required this.sessionType,
    this.decodedSessions = const []
  });

  factory UserStatus.initial() =>
      UserStatus.empty().copyWith(
        compatibilityHash: Config.latestCompatHash,
        onlineStatus: OnlineStatus.offline,
        hashSalt: CryptoHelper.cryptoToken(),
        outputDevice: null,
        userSessionId: const Uuid().v4(),
        sessionType: UserSessionType.chatClient,
        isPresent: true,
      );

  factory UserStatus.empty() =>
      UserStatus(
        userId: "",
        onlineStatus: OnlineStatus.offline,
        lastStatusChange: DateTime.now(),
        lastPresenceTimestamp: DateTime.now(),
        userSessionId: "",
        currentSessionIndex: -1,
        sessions: [],
        appVersion: "",
        outputDevice: null,
        isMobile: false,
        isPresent: false,
        compatibilityHash: "",
        hashSalt: "",
        sessionType: UserSessionType.unknown
      );

  factory UserStatus.fromMap(Map map) {
    return UserStatus(
      userId: map["userId"] ?? "",
      onlineStatus: OnlineStatus.parse(map["onlineStatus"]),
      lastStatusChange: DateTime.tryParse(map["lastStatusChange"] ?? "") ?? DateTime.now(),
      lastPresenceTimestamp: DateTime.tryParse(map["lastPresenceTimestamp"] ?? "") ?? DateTime.now(),
      userSessionId: map["userSessionId"] ?? "",
      isPresent: map["isPresent"] ?? false,
      currentSessionIndex: map["currentSessionIndex"] ?? -1,
      sessions: (map["sessions"] as List? ?? []).map((e) => SessionMetadata.fromMap(e)).toList(),
      appVersion: map["appVersion"] ?? "",
      outputDevice: map["outputDevice"] ?? "Unknown",
      isMobile: map["isMobile"] ?? false,
      compatibilityHash: map["compatibilityHash"] ?? "",
      hashSalt: map["hashSalt"] ?? "",
      sessionType: UserSessionType.fromString(map["sessionType"])
    );
  }

  Map toMap({bool shallow = false}) {
    return {
      "userId": userId,
      "onlineStatus": toBeginningOfSentenceCase(onlineStatus.name),
      "lastStatusChange": lastStatusChange.toUtc().toIso8601String(),
      "isPresent": isPresent,
      "lastPresenceTimestamp": lastPresenceTimestamp.toUtc().toIso8601String(),
      "userSessionId": userSessionId,
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
      "sessionType": toBeginningOfSentenceCase(sessionType.name)
    };
  }

  UserStatus copyWith({
    String? userId,
    OnlineStatus? onlineStatus,
    DateTime? lastStatusChange,
    DateTime? lastPresenceTimestamp,
    bool? isPresent,
    String? userSessionId,
    int? currentSessionIndex,
    List<SessionMetadata>? sessions,
    String? appVersion,
    String? Function()? outputDevice,
    bool? isMobile,
    String? compatibilityHash,
    String? hashSalt,
    UserSessionType? sessionType,
    List<Session>? decodedSessions,
  }) =>
      UserStatus(
        userId: userId ?? this.userId,
        onlineStatus: onlineStatus ?? this.onlineStatus,
        lastStatusChange: lastStatusChange ?? this.lastStatusChange,
        lastPresenceTimestamp: lastPresenceTimestamp ?? this.lastPresenceTimestamp,
        isPresent: isPresent ?? this.isPresent,
        userSessionId: userSessionId ?? this.userSessionId,
        currentSessionIndex: currentSessionIndex ?? this.currentSessionIndex,
        sessions: sessions ?? this.sessions,
        appVersion: appVersion ?? this.appVersion,
        outputDevice: outputDevice == null ? this.outputDevice : outputDevice(),
        isMobile: isMobile ?? this.isMobile,
        compatibilityHash: compatibilityHash ?? this.compatibilityHash,
        hashSalt: hashSalt ?? this.hashSalt,
        sessionType: sessionType ?? this.sessionType,
        decodedSessions: decodedSessions ?? this.decodedSessions,
      );
}
