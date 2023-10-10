import 'package:recon/auxiliary.dart';

class Entitlement {
  Entitlement();

  factory Entitlement.fromMap(Map map) {
    final type = map["\$type"];

    return switch (type) {
      "storageSpace" => StorageSpace.fromMap(map),
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
