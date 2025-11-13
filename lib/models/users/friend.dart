import 'package:recon/auxiliary.dart';
import 'package:recon/models/users/friend_status.dart';
import 'package:recon/models/users/online_status.dart';
import 'package:recon/models/users/user_profile.dart';
import 'package:recon/models/users/user_status.dart';

class Friend implements Comparable {
  static const _emptyId = "-1";
  static const _resoniteBotId = "U-Resonite";
  final String id;
  final String username;
  final String ownerId;
  final UserStatus userStatus;
  final UserProfile userProfile;
  final FriendStatus contactStatus;
  final DateTime latestMessageTime;

  const Friend({
    required this.id,
    required this.username,
    required this.ownerId,
    required this.userStatus,
    required this.userProfile,
    required this.contactStatus,
    required this.latestMessageTime,
  });

  bool get isHeadless => userStatus.sessionType == UserSessionType.headless;

  bool get isBot => userStatus.sessionType == UserSessionType.bot || id == _resoniteBotId;

  bool get isSociable =>
      (userStatus.onlineStatus == OnlineStatus.sociable) &&
      !isBot &&
      !isHeadless;

  bool get isOffline =>
      (userStatus.onlineStatus == OnlineStatus.offline || userStatus.onlineStatus == OnlineStatus.invisible) &&
      !isBot &&
      !isHeadless;

  bool get isOnline => !isOffline;

  factory Friend.fromMap(Map map) {
    var userStatus = map["userStatus"] == null ? UserStatus.empty() : UserStatus.fromMap(map["userStatus"]);
    return Friend(
      id: map["id"],
      username: map["contactUsername"],
      ownerId: map["ownerId"] ?? map["id"],
      // Resonite bot status is always offline but should be displayed as online
      userStatus: map["id"] == _resoniteBotId ? userStatus.copyWith(onlineStatus: OnlineStatus.online) : userStatus,
      userProfile: UserProfile.fromMap(map["profile"] ?? {}),
      contactStatus: FriendStatus.fromString(map["contactStatus"]),
      latestMessageTime: map["latestMessageTime"] == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.parse(map["latestMessageTime"]),
    );
  }

  static Friend? fromMapOrNull(Map? map) {
    if (map == null) return null;
    return Friend.fromMap(map);
  }

  factory Friend.empty() {
    return Friend(
      id: _emptyId,
      username: "",
      ownerId: "",
      userStatus: UserStatus.empty(),
      userProfile: UserProfile.empty(),
      contactStatus: FriendStatus.none,
      latestMessageTime: DateTimeX.epoch,
    );
  }

  bool get isEmpty => id == _emptyId;

  Friend copyWith(
      {String? id,
      String? username,
      String? ownerId,
      UserStatus? userStatus,
      UserProfile? userProfile,
      FriendStatus? contactStatus,
      DateTime? latestMessageTime}) {
    return Friend(
      id: id ?? this.id,
      username: username ?? this.username,
      ownerId: ownerId ?? this.ownerId,
      userStatus: userStatus ?? this.userStatus,
      userProfile: userProfile ?? this.userProfile,
      contactStatus: contactStatus ?? this.contactStatus,
      latestMessageTime: latestMessageTime ?? this.latestMessageTime,
    );
  }

  Map toMap({bool shallow = false}) {
    return {
      "id": id,
      "contactUsername": username,
      "ownerId": ownerId,
      "userStatus": userStatus.toMap(shallow: shallow),
      "profile": userProfile.toMap(),
      "contactStatus": contactStatus.name,
      "latestMessageTime": latestMessageTime.toUtc().toIso8601String(),
    };
  }

  @override
  int compareTo(covariant Friend other) {
    return username.compareTo(other.username);
  }
}
