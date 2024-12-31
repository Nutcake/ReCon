import 'package:recon/auxiliary.dart';

class Entitlement {
  Entitlement();

  factory Entitlement.fromMap(Map map) {
    final type = map["\$type"];

    return switch (type) {
      "storageSpace" => StorageSpace.fromMap(map),
      "badge" => Badge.fromMap(map),
      "shoutOut" => ShoutOut.fromMap(map),
      "credits" => Credits.fromMap(map),
      _ => Entitlement(),
    };
  }
}

class StorageSpace extends Entitlement {
  final int bytes;
  final int maximumShareLevel;
  final String storageId;
  final String group;
  final DateTime startsOn;
  final DateTime expiresOn;
  final String name;
  final String description;

  StorageSpace({
    required this.bytes,
    required this.maximumShareLevel,
    required this.storageId,
    required this.group,
    required this.startsOn,
    required this.expiresOn,
    required this.name,
    required this.description,
  });

  factory StorageSpace.fromMap(Map map) {
    return StorageSpace(
      bytes: map["bytes"],
      maximumShareLevel: map["maximumShareLevel"],
      storageId: map["storageId"],
      group: map["group"],
      startsOn: DateTime.tryParse(map["startsOn"] ?? "") ?? DateTimeX.epoch,
      expiresOn: DateTime.tryParse(map["expiresOn"] ?? "") ?? DateTimeX.epoch,
      name: map["name"],
      description: map["description"],
    );
  }
}

enum BadgeType {
  static2D,
  model
}

class Badge extends Entitlement {
  final BadgeType badgeType;
  final int badgeCount;
  final List<String> entitlementOrigins;

  Badge({
    required this.badgeType,
    required this.badgeCount,
    required this.entitlementOrigins,
  });

  factory Badge.fromMap(Map map) {
    return Badge(
      badgeType: BadgeType.values.firstWhere((e) => e.name == map["badgeType"], orElse: () => BadgeType.static2D),
      badgeCount: map["badgeCount"],
      entitlementOrigins: List<String>.from(map["entitlementOrigins"] ?? []),
    );
  }
}

class ShoutOut extends Entitlement {
  final String shoutoutType;
  final List<String> entitlementOrigins;

  ShoutOut({
    required this.shoutoutType,
    required this.entitlementOrigins,
  });

  factory ShoutOut.fromMap(Map map) {
    return ShoutOut(
      shoutoutType: map["shoutoutType"],
      entitlementOrigins: List<String>.from(map["entitlementOrigins"] ?? []),
    );
  }
}

enum CreditType {
  basic,
  prominent,
  spoken,
  sponsor
}

class Credits extends Entitlement {
  final CreditType creditType;
  final List<String> entitlementOrigins;

  Credits({
    required this.creditType,
    required this.entitlementOrigins,
  });

  factory Credits.fromMap(Map map) {
    return Credits(
      creditType: CreditType.values.firstWhere((e) => e.name == map["creditType"], orElse: () => CreditType.basic),
      entitlementOrigins: List<String>.from(map["entitlementOrigins"] ?? []),
    );
  }
}
