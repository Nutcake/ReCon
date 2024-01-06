import 'package:recon/auxiliary.dart';
import 'package:recon/models/users/user_profile.dart';
import 'package:recon/models/users/contact_status.dart';
import 'package:recon/models/users/online_status.dart';
import 'package:recon/models/users/user_status.dart';

class Contact implements Comparable {
  static const _emptyId = "-1";
  static const _resoniteBotId = "U-Resonite";
  final String id;
  final String contactUsername;
  final String ownerId;
  final UserStatus userStatus;
  final UserProfile userProfile;
  final ContactStatus friendStatus;
  final DateTime latestMessageTime;

  const Contact({required this.id, required this.contactUsername, required this.ownerId, required this.userStatus, required this.userProfile,
    required this.friendStatus, required this.latestMessageTime,
  });

  bool get isHeadless => userStatus.outputDevice == "Headless";

  factory Contact.fromMap(Map map) {
    var userStatus = map["userStatus"] == null ? UserStatus.empty() : UserStatus.fromMap(map["userStatus"]);
    return Contact(
      id: map["id"],
      contactUsername: map["contactUsername"],
      ownerId: map["ownerId"] ?? map["id"],
      // Neos bot status is always offline but should be displayed as online
      userStatus:  map["id"] == _resoniteBotId ? userStatus.copyWith(onlineStatus: OnlineStatus.online) : userStatus,
      userProfile: UserProfile.fromMap(map["profile"] ?? {}),
      friendStatus: ContactStatus.fromString(map["contactStatus"]),
      latestMessageTime: map["latestMessageTime"] == null
          ? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.parse(map["latestMessageTime"]),
    );
  }

  static Contact? fromMapOrNull(Map? map) {
    if (map == null) return null;
    return Contact.fromMap(map);
  }

  factory Contact.empty() {
    return Contact(
        id: _emptyId,
        contactUsername: "",
        ownerId: "",
        userStatus: UserStatus.empty(),
        userProfile: UserProfile.empty(),
        friendStatus: ContactStatus.none,
        latestMessageTime: DateTimeX.epoch
    );
  }

  bool get isEmpty => id == _emptyId;

  Contact copyWith({
    String? id, String? contactUsername, String? ownerId, UserStatus? userStatus, UserProfile? userProfile,
    ContactStatus? friendStatus, DateTime? latestMessageTime}) {
    return Contact(
      id: id ?? this.id,
      contactUsername: contactUsername ?? this.contactUsername,
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
      "contactUsername": contactUsername,
      "ownerId": ownerId,
      "userStatus": userStatus.toMap(shallow: shallow),
      "profile": userProfile.toMap(),
      "contactStatus": friendStatus.name,
      "latestMessageTime": latestMessageTime.toIso8601String(),
    };
  }

  @override
  int compareTo(covariant Contact other) {
    return contactUsername.compareTo(other.contactUsername);
  }
}
