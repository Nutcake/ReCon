import 'package:recon/auxiliary.dart';
import 'package:recon/models/users/entitlement.dart';
import 'package:recon/models/users/user_profile.dart';

class PersonalProfile {
  final String id;
  final String username;
  final String email;
  final DateTime? publicBanExpiration;
  final String? publicBanType;
  final bool twoFactor;
  final UserProfile userProfile;
  final List<Entitlement> entitlements;
  final List<SupporterMetadata> supporterMetadata;

  PersonalProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.publicBanExpiration,
    required this.publicBanType,
    required this.twoFactor,
    required this.userProfile,
    required this.entitlements,
    required this.supporterMetadata,
  });

  factory PersonalProfile.fromMap(Map map) {
    return PersonalProfile(
      id: map["id"] ?? "",
      username: map["username"] ?? "",
      email: map["email"] ?? "",
      publicBanExpiration: DateTime.tryParse(map["publicBanExpiration"] ?? ""),
      publicBanType: map["publicBanType"],
      twoFactor: map["2fa_login"] ?? false,
      userProfile: UserProfile.fromMap(map["profile"]),
      entitlements: ((map["entitlements"] ?? []) as List).map((e) => Entitlement.fromMap(e)).toList(),
      supporterMetadata: ((map["supporterMetadata"] ?? []) as List).map((e) => SupporterMetadata.fromMap(e)).toList(),
    );
  }
  
  /// Has supported anywhere
  bool get isSupporter => supporterMetadata.any((element) => element.TotalSupportMonths > 0);

  /// Actively supporting
  bool get isAnyActiveSupporter => supporterMetadata.any((element) => element.isActiveSupporter);

  /// Actively supporting on Patreon
  bool get isPatreonSupporter => supporterMetadata.any((element) => element.type == "patreon" && element.isActiveSupporter);

  /// Actively supporting on Stripe
  bool get isStripeSupporter => supporterMetadata.any((element) => element.type == "stripe" && element.isActiveSupporter);
}

class StorageQuota {
  final String id;
  final int usedBytes;
  final int quotaBytes;
  final int fullQuotaBytes;

  StorageQuota({
    required this.id,
    required this.usedBytes,
    required this.quotaBytes,
    required this.fullQuotaBytes,
  });

  factory StorageQuota.fromMap(Map map) {
    return StorageQuota(
      id: map["id"] ?? "",
      usedBytes: map["usedBytes"] ?? 0,
      quotaBytes: map["quotaBytes"] ?? 0,
      fullQuotaBytes: map["fullQuotaBytes"] ?? 0,
    );
  }
}

class SupporterMetadata {
  SupporterMetadata();

  factory SupporterMetadata.fromMap(Map map) {
    final type = map["\$type"];
    return switch (type) {
      "patreon" => SubscriptionSupporter.fromMap(map),
      "stripe" => SubscriptionSupporter.fromMap(map),
      _ => SupporterMetadata()
    }
  }
}

class SubscriptionSupporter extends SupporterMetadata {
  final String type;
  final bool isActiveSupporter;
  final int totalSupportMonths;
  final int totalSupportCents;
  final int lastTierCents;
  final int highestTierCents;
  final int lowestTierCents;
  final DateTime firstSupportTimestamp;
  final DateTime lastSupportTimestamp;

  SubscriptionSupporter({
    required this.type,
    required this.isActiveSupporter,
    required this.totalSupportMonths,
    required this.totalSupportCents,
    required this.lastTierCents,
    required this.highestTierCents,
    required this.lowestTierCents,
    required this.firstSupportTimestamp,
    required this.lastSupportTimestamp,
  });

  factory SubscriptionSupporter.fromMap(Map map) {
    return SubscriptionSupporter(
      type: map["\$type"] ?? "unknown",
      isActiveSupporter: map["isActiveSupporter"],
      totalSupportMonths: map["totalSupportMonths"],
      totalSupportCents: map["totalSupportCents"],
      lastTierCents: map["lastTierCents"],
      highestTierCents: map["highestTierCents"],
      lowestTierCents: map["lowestTierCents"],
      firstSupportTimestamp: DateTime.tryParse(map["firstSupportTimestamp"] ?? "") ?? DateTimeX.epoch,
      lastSupportTimestamp: DateTime.tryParse(map["lastSupportTimestamp"] ?? "") ?? DateTimeX.epoch,
    );
  }
}
