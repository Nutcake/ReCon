import 'package:recon/auxiliary.dart';
import 'package:recon/models/users/friend_status.dart';
import 'package:recon/models/users/online_status.dart';
import 'package:recon/models/users/user_profile.dart';
import 'package:recon/models/users/user_status.dart';

class Friend implements Comparable {
  static const _emptyId = "-1";
  static const _resoniteBotId = "U-Resonite";
  final String contactUserId;
  final String contactUsername;
  final String ownerId;
  final UserStatus userStatus;
  final UserProfile userProfile;
  final ContactStatus contactStatus;
  final DateTime latestMessageTime;
  final bool isAccepted;

  const Friend({
    required this.contactUserId,
    required this.contactUsername,
    required this.ownerId,
    required this.userStatus,
    required this.userProfile,
    required this.contactStatus,
    required this.latestMessageTime,
    required this.isAccepted,
  });

  bool get isHeadless => userStatus.sessionType == UserSessionType.headless;

  bool get isBot => userStatus.sessionType == UserSessionType.bot || contactUserId == _resoniteBotId;

  bool get isSociable => (userStatus.onlineStatus == OnlineStatus.sociable) && !isBot && !isHeadless;

  bool get isOffline => (userStatus.onlineStatus == OnlineStatus.offline || userStatus.onlineStatus == OnlineStatus.invisible) && !isBot && !isHeadless;

  bool get isOnline => !isOffline;

  factory Friend.fromMap(Map map) {
    final userStatus = map["userStatus"] == null ? UserStatus.empty() : UserStatus.fromMap(map["userStatus"]);
    return Friend(
      contactUserId: map["id"],
      contactUsername: map["contactUsername"],
      ownerId: map["ownerId"] ?? map["id"],
      // Resonite bot status is always offline but should be displayed as online
      userStatus: map["id"] == _resoniteBotId ? userStatus.copyWith(onlineStatus: OnlineStatus.online) : userStatus,
      userProfile: UserProfile.fromMap(map["profile"] ?? {}),
      contactStatus: ContactStatus.fromString(map["contactStatus"]),
      latestMessageTime: map["latestMessageTime"] == null ? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.parse(map["latestMessageTime"]),
      isAccepted: map["isAccepted"] ?? false,
    );
  }

  static Friend? fromMapOrNull(Map? map) {
    if (map == null) return null;
    return Friend.fromMap(map);
  }

  factory Friend.empty() {
    return Friend(
      contactUserId: _emptyId,
      contactUsername: "",
      ownerId: "",
      userStatus: UserStatus.empty(),
      userProfile: UserProfile.empty(),
      contactStatus: ContactStatus.none,
      latestMessageTime: DateTimeX.epoch,
      isAccepted: false,
    );
  }

  bool get isEmpty => contactUserId == _emptyId;

  Friend copyWith({
    String? contactUserId,
    String? contactUsername,
    String? ownerId,
    UserStatus? userStatus,
    UserProfile? userProfile,
    ContactStatus? contactStatus,
    DateTime? latestMessageTime,
    bool? isAccepted,
  }) {
    return Friend(
      contactUserId: contactUserId ?? this.contactUserId,
      contactUsername: contactUsername ?? this.contactUsername,
      ownerId: ownerId ?? this.ownerId,
      userStatus: userStatus ?? this.userStatus,
      userProfile: userProfile ?? this.userProfile,
      contactStatus: contactStatus ?? this.contactStatus,
      latestMessageTime: latestMessageTime ?? this.latestMessageTime,
      isAccepted: isAccepted ?? this.isAccepted,
    );
  }

  Map toMap({bool shallow = false}) {
    return {
      "id": contactUserId,
      "contactUsername": contactUsername,
      "ownerId": ownerId,
      "userStatus": userStatus.toMap(shallow: shallow),
      "profile": userProfile.toMap(),
      "contactStatus": contactStatus.name,
      "latestMessageTime": latestMessageTime.toUtc().toIso8601String(),
      "isAccepted": isAccepted,
    };
  }

  @override
  int compareTo(covariant Friend other) {
    return contactUsername.compareTo(other.contactUsername);
  }
}
