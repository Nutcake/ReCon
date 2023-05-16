import 'package:contacts_plus_plus/auxiliary.dart';
import 'package:contacts_plus_plus/models/records/neos_db_asset.dart';
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

class RecordId {
  final String? id;
  final String? ownerId;
  final bool isValid;

  const RecordId({required this.id, required this.ownerId, required this.isValid});

  factory RecordId.fromMap(Map? map) {
    return RecordId(id: map?["id"], ownerId: map?["ownerId"], isValid: map?["isValid"] ?? false);
  }

  Map toMap() {
    return {
      "id": id,
      "ownerId": ownerId,
      "isValid": isValid,
    };
  }
}

class Record {
  final int id;
  final RecordId combinedRecordId;
  final String recordId;
  final String ownerId;
  final String assetUri;
  final int globalVersion;
  final int localVersion;
  final String lastModifyingUserId;
  final String lastModifyingMachineId;
  final bool isSynced;
  final DateTime fetchedOn;
  final String name;
  final FormatNode formattedName;
  final String description;
  final RecordType recordType;
  final List<String> tags;
  final String path;
  final String thumbnailUri;
  final bool isPublic;
  final bool isForPatreons;
  final bool isListed;
  final DateTime lastModificationTime;
  final DateTime creationTime;
  final int visits;
  final int rating;
  final int randomOrder;
  final List<String> manifest;
  final List<NeosDBAsset> neosDBManifest;
  final String url;
  final bool isValidOwnerId;
  final bool isValidRecordId;

  Record({
    required this.id,
    required this.combinedRecordId,
    required this.recordId,
    required this.isSynced,
    required this.fetchedOn,
    required this.path,
    required this.ownerId,
    required this.assetUri,
    required this.name,
    required this.description,
    required this.tags,
    required this.recordType,
    required this.thumbnailUri,
    required this.isPublic,
    required this.isListed,
    required this.isForPatreons,
    required this.lastModificationTime,
    required this.neosDBManifest,
    required this.lastModifyingUserId,
    required this.lastModifyingMachineId,
    required this.creationTime,
    required this.manifest,
    required this.url,
    required this.isValidOwnerId,
    required this.isValidRecordId,
    required this.globalVersion,
    required this.localVersion,
    required this.visits,
    required this.rating,
    required this.randomOrder,
  }) : formattedName = FormatNode.fromText(name);

  factory Record.fromMap(Map map) {
    return Record(
      id: map["id"] ?? 0,
      combinedRecordId: RecordId.fromMap(map["combinedRecordId"]),
      recordId: map["recordId"],
      ownerId: map["ownerId"] ?? "",
      assetUri: map["assetUri"] ?? "",
      globalVersion: map["globalVersion"] ?? 0,
      localVersion: map["localVersion"] ?? 0,
      name: map["name"] ?? "",
      description: map["description"] ?? "",
      tags: (map["tags"] as List? ?? []).map((e) => e.toString()).toList(),
      recordType: RecordType.fromName(map["recordType"]),
      thumbnailUri: map["thumbnailUri"] ?? "",
      isPublic: map["isPublic"] ?? false,
      isForPatreons: map["isForPatreons"] ?? false,
      isListed: map["isListed"] ?? false,
      lastModificationTime: DateTime.tryParse(map["lastModificationTime"]) ?? DateTimeX.epoch,
      neosDBManifest: (map["neosDBManifest"] as List? ?? []).map((e) => NeosDBAsset.fromMap(e)).toList(),
      lastModifyingUserId: map["lastModifyingUserId"] ?? "",
      lastModifyingMachineId: map["lastModifyingMachineId"] ?? "",
      creationTime: DateTime.tryParse(map["lastModificationTime"]) ?? DateTimeX.epoch,
      isSynced: map["isSynced"] ?? false,
      fetchedOn: DateTime.tryParse(map["fetchedOn"]) ?? DateTimeX.epoch,
      path: map["path"] ?? "",
      manifest: (map["neosDBManifest"] as List? ?? []).map((e) => e.toString()).toList(),
      url: map["url"] ?? "",
      isValidOwnerId: map["isValidOwnerId"] ?? "",
      isValidRecordId: map["isValidRecordId"] ?? "",
      visits: map["visits"] ?? 0,
      rating: map["rating"] ?? 0,
      randomOrder: map["randomOrder"] ?? 0
    );
  }

  Record copyWith({
    int? id,
    String? ownerId,
    String? recordId,
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
    RecordId? combinedRecordId,
    bool? isSynced,
    DateTime? fetchedOn,
    String? path,
    List<String>? manifest,
    String? url,
    bool? isValidOwnerId,
    bool? isValidRecordId,
    int? visits,
    int? rating,
    int? randomOrder,
  }) {
    return Record(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      recordId: recordId ?? this.recordId,
      assetUri: assetUri ?? this.assetUri,
      globalVersion: globalVersion ?? this.globalVersion,
      localVersion: localVersion ?? this.localVersion,
      name: name ?? this.name,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      recordType: recordType ?? this.recordType,
      thumbnailUri: thumbnailUri ?? this.thumbnailUri,
      isPublic: isPublic ?? this.isPublic,
      isForPatreons: isForPatreons ?? this.isForPatreons,
      isListed: isListed ?? this.isListed,
      lastModificationTime: lastModificationTime ?? this.lastModificationTime,
      neosDBManifest: neosDBManifest ?? this.neosDBManifest,
      lastModifyingUserId: lastModifyingUserId ?? this.lastModifyingUserId,
      lastModifyingMachineId: lastModifyingMachineId ?? this.lastModifyingMachineId,
      creationTime: creationTime ?? this.creationTime,
      combinedRecordId: combinedRecordId ?? this.combinedRecordId,
      isSynced: isSynced ?? this.isSynced,
      fetchedOn: fetchedOn ?? this.fetchedOn,
      path: path ?? this.path,
      manifest: manifest ?? this.manifest,
      url: url ?? this.url,
      isValidOwnerId: isValidOwnerId ?? this.isValidOwnerId,
      isValidRecordId: isValidRecordId ?? this.isValidRecordId,
      visits: visits ?? this.visits,
      rating: rating ?? this.rating,
      randomOrder: randomOrder ?? this.randomOrder,
    );
  }

  Map toMap() {
    return {
      "id": id,
      "ownerId": ownerId,
      "recordId": recordId,
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
      "lastModificationTime": lastModificationTime.toUtc().toIso8601String(),
      "neosDBManifest": neosDBManifest.map((e) => e.toMap()).toList(),
      "lastModifyingUserId": lastModifyingUserId,
      "lastModifyingMachineId": lastModifyingMachineId,
      "creationTime": creationTime.toUtc().toIso8601String(),
      "combinedRecordId": combinedRecordId.toMap(),
      "isSynced": isSynced,
      "fetchedOn": fetchedOn.toUtc().toIso8601String(),
      "path": path,
      "manifest": manifest,
      "url": url,
      "isValidOwnerId": isValidOwnerId,
      "isValidRecordId": isValidRecordId,
      "visits": visits,
      "rating": rating,
      "randomOrder": randomOrder,
    };
  }

  static String generateId() {
    return "R-${const Uuid().v4()}";
  }
}