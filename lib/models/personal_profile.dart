import 'package:flutter/material.dart';
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
  final List<String> tags;
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
    required this.tags,
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
      tags: (map["tags"] ?? []).cast<String>(),
      userProfile: UserProfile.fromMap(map["profile"]),
      entitlements: ((map["entitlements"] ?? []) as List).map((e) => Entitlement.fromMap(e)).toList(),
      supporterMetadata: ((map["supporterMetadata"] ?? []) as List).map((e) => SupporterMetadata.fromMap(e)).toList(),
    );
  }

  bool get isPatreonSupporter =>
      supporterMetadata.whereType<PatreonSupporter>().any((element) => element.isActiveSupporter);

  AccountType get accountType => tags.contains("team member")
      ? AccountType(label: "Resonite Team", color: const Color.fromARGB(255, 255, 230, 0))
      : tags.contains("moderator")
          ? AccountType(label: "Resonite Moderator", color: const Color(0xFF61D1FA))
          : tags.contains("mentor")
              ? AccountType(label: "Resonite Mentor", color: const Color(0xFF59EB5C))
              : isPatreonSupporter
                  ? AccountType(label: "Patreon Supporter", color: const Color(0xFFFF7676))
                  : AccountType(label: "Standard Account", color: const Color(0xFF86888B));
}

class AccountType {
  final String label;
  final Color color;

  AccountType({
    required this.label,
    required this.color,
  });
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
      "patreon" => PatreonSupporter.fromMap(map),
      _ => SupporterMetadata(),
    };
  }
}

class PatreonSupporter extends SupporterMetadata {
  final bool isActiveSupporter;
  final int totalSupportMonths;
  final int totalSupportCents;
  final int lastTierCents;
  final int highestTierCents;
  final int lowestTierCents;
  final DateTime firstSupportTimestamp;
  final DateTime lastSupportTimestamp;

  PatreonSupporter({
    required this.isActiveSupporter,
    required this.totalSupportMonths,
    required this.totalSupportCents,
    required this.lastTierCents,
    required this.highestTierCents,
    required this.lowestTierCents,
    required this.firstSupportTimestamp,
    required this.lastSupportTimestamp,
  });

  factory PatreonSupporter.fromMap(Map map) {
    return PatreonSupporter(
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
