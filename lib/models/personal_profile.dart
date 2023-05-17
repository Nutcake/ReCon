
import 'package:collection/collection.dart';
import 'package:contacts_plus_plus/models/user_profile.dart';

class PersonalProfile {
  final String id;
  final String username;
  final String email;
  final DateTime? publicBanExpiration;
  final String? publicBanType;
  final List<StorageQuotas> storageQuotas;
  final Map<String, int> quotaBytesSource;
  final int quotaBytes;
  final int usedBytes;
  final bool twoFactor;
  final bool isPatreonSupporter;
  final UserProfile userProfile;

  PersonalProfile({
    required this.id, required this.username, required this.email, required this.publicBanExpiration,
    required this.publicBanType, required this.storageQuotas, required this.quotaBytesSource, required this.quotaBytes,
    required this.usedBytes, required this.twoFactor, required this.isPatreonSupporter, required this.userProfile,
  });

  factory PersonalProfile.fromMap(Map map) {
    return PersonalProfile(
      id: map["id"] ?? "",
      username: map["username"] ?? "",
      email: map["email"] ?? "",
      publicBanExpiration: DateTime.tryParse(map["publicBanExpiration"] ?? ""),
      publicBanType: map["publicBanType"],
      storageQuotas: (map["storageQuotas"] as List? ?? []).map((e) => StorageQuotas.fromMap(e)).toList(),
      quotaBytesSource: (map["quotaBytesSources"] as Map? ?? {}).map((key, value) => MapEntry(key, value as int)),
      quotaBytes: map["quotaBytes"] ?? 0,
      usedBytes: map["usedBytes"] ?? 0,
      twoFactor: map["2fa_login"] ?? false,
      isPatreonSupporter: map["patreonData"]?["isPatreonSupporter"] ?? false,
      userProfile: UserProfile.fromMap(map["profile"]),
    );
  }
}

class StorageQuotas {
  final String id;
  final int bytes;
  final DateTime addedOn;
  final DateTime expiresOn;
  final String giftedByUserId;

  StorageQuotas({required this.id, required this.bytes, required this.addedOn, required this.expiresOn,
    required this.giftedByUserId});

  factory StorageQuotas.fromMap(Map map) {
    return StorageQuotas(
      id: map["id"] ?? "",
      bytes: map["bytes"] ?? 0,
      addedOn: DateTime.tryParse(map["addedOn"]) ?? DateTime.fromMillisecondsSinceEpoch(0),
      expiresOn: DateTime.tryParse(map["expiresOn"]) ?? DateTime.fromMillisecondsSinceEpoch(0),
      giftedByUserId: map["giftedByUserId"] ?? "",
    );
  }
}