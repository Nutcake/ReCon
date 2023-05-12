import 'package:contacts_plus_plus/models/asset/neos_db_asset.dart';
import 'package:contacts_plus_plus/string_formatter.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum RecordType {
  unknown,
  link,
  object,
  directory,
  texture,
  audio;

  factory RecordType.fromName(String? name) {
    return RecordType.values.firstWhere((element) => element.name.toLowerCase() == name?.toLowerCase().trim(), orElse: () => RecordType.unknown);
  }
}

class Record {
  final String id;
  final String ownerId;
  final String? assetUri;
  final int globalVersion;
  final int localVersion;
  final String name;
  final TextSpan? formattedName;
  final String? description;
  final List<String>? tags;
  final String? thumbnailUri;
  final bool isPublic;
  final bool isForPatreons;
  final bool isListed;
  final bool isDeleted;
  final DateTime? lastModificationTime;
  final List<NeosDBAsset> neosDBManifest;
  final String lastModifyingUserId;
  final String lastModifyingMachineId;
  final DateTime? creationTime;
  final RecordType recordType;

  const Record({
    required this.id,
    this.formattedName,
    required this.ownerId,
    this.assetUri,
    this.globalVersion=0,
    this.localVersion=0,
    required this.name,
    this.description,
    this.tags,
    required this.recordType,
    this.thumbnailUri,
    required this.isPublic,
    required this.isListed,
    required this.isDeleted,
    required this.isForPatreons,
    this.lastModificationTime,
    required this.neosDBManifest,
    required this.lastModifyingUserId,
    required this.lastModifyingMachineId,
    this.creationTime,
  });

  factory Record.fromMap(Map map) {
    return Record(
      id: map["id"],
      ownerId: map["ownerId"],
      assetUri: map["assetUri"],
      globalVersion: map["globalVersion"] ?? 0,
      localVersion: map["localVersion"] ?? 0,
      name: map["name"] ?? "",
      formattedName: StringFormatter.tryFormat(map["name"]),
      description: map["description"],
      tags: (map["tags"] as List? ?? []).map((e) => e.toString()).toList(),
      recordType: RecordType.fromName(map["recordType"]),
      thumbnailUri: map["thumbnailUri"],
      isPublic: map["isPublic"] ?? false,
      isForPatreons: map["isForPatreons"] ?? false,
      isListed: map["isListed"] ?? false,
      isDeleted: map["isDeleted"] ?? false,
      lastModificationTime: DateTime.tryParse(map["lastModificationTime"]),
      neosDBManifest: (map["neosDBManifest"] as List? ?? []).map((e) => NeosDBAsset.fromMap(e)).toList(),
      lastModifyingUserId: map["lastModifyingUserId"] ?? "",
      lastModifyingMachineId: map["lastModifyingMachineId"] ?? "",
      creationTime: DateTime.tryParse(map["lastModificationTime"]),
    );
  }

  Record copyWith({
    String? id,
    String? ownerId,
    String? assetUri,
    int? globalVersion,
    int? localVersion,
    String? name,
    TextSpan? formattedName,
    String? description,
    List<String>? tags,
    RecordType? recordType,
    String? thumbnailUri,
    bool? isPublic,
    bool? isForPatreons,
    bool? isListed,
    bool? isDeleted,
    DateTime? lastModificationTime,
    List<NeosDBAsset>? neosDBManifest,
    String? lastModifyingUserId,
    String? lastModifyingMachineId,
    DateTime? creationTime,
  }) {
    return Record(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      assetUri: assetUri ?? this.assetUri,
      globalVersion: globalVersion ?? this.globalVersion,
      localVersion: localVersion ?? this.localVersion,
      name: name ?? this.name,
      formattedName: formattedName ?? this.formattedName,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      recordType: recordType ?? this.recordType,
      thumbnailUri: thumbnailUri ?? this.thumbnailUri,
      isPublic: isPublic ?? this.isPublic,
      isForPatreons: isForPatreons ?? this.isForPatreons,
      isListed: isListed ?? this.isListed,
      isDeleted: isDeleted ?? this.isDeleted,
      lastModificationTime: lastModificationTime ?? this.lastModificationTime,
      neosDBManifest: neosDBManifest ?? this.neosDBManifest,
      lastModifyingUserId: lastModifyingUserId ?? this.lastModifyingUserId,
      lastModifyingMachineId: lastModifyingMachineId ?? this.lastModifyingMachineId,
      creationTime: creationTime ?? this.creationTime,
    );
  }

  Map toMap() {
    return {
      "id": id,
      "ownerId": ownerId,
      "assetUri": assetUri,
      "globalVersion": globalVersion,
      "localVersion": localVersion,
      "name": name,
      "description": description,
      "tags": tags,
      "recordType": recordType.name,
      "thumbnailUri": thumbnailUri,
      "isPublic": isPublic,
      "isForPatreons": isForPatreons,
      "isListed": isListed,
      "isDeleted": isDeleted,
      "lastModificationTime": lastModificationTime?.toIso8601String(),
      "neosDBManifest": neosDBManifest.map((e) => e.toMap()).toList(),
      "lastModifyingUserId": lastModifyingUserId,
      "lastModifyingMachineId": lastModifyingMachineId,
      "creationTime": creationTime?.toIso8601String(),
    };
  }

  static String generateId() {
    return "R-${const Uuid().v4()}";
  }
}