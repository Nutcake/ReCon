import 'package:recon/auxiliary.dart';
import 'package:recon/models/records/asset_manifest.dart';
import 'package:recon/models/records/record_version.dart';
import 'package:recon/string_formatter.dart';
import 'package:uuid/uuid.dart';

enum RecordType {
  unknown,
  link,
  object,
  directory,
  texture,
  audio;

  factory RecordType.fromName(String? name) {
    return RecordType.values.firstWhere(
      (element) => element.name.toLowerCase() == name?.toLowerCase().trim(),
      orElse: () => RecordType.unknown,
    );
  }
}

class Record {
  static final _rootRecord = Record(
    id: "0",
    path: "Inventory",
    ownerId: "",
    assetUri: "",
    name: "Inventory",
    version: RecordVersion(
      globalVersion: 1,
      localVersion: 1,
      lastModifyingUserId: null,
      lastModifyingMachineId: null,
    ),
    description: "",
    tags: [],
    recordType: RecordType.directory,
    thumbnailUri: "",
    isPublic: false,
    isListed: false,
    isForPatreons: false,
    lastModificationTime: DateTimeX.epoch,
    creationTime: DateTimeX.epoch,
    assetManifest: [],
    visits: 0,
    rating: 0,
    randomOrder: 0,
    ownerName: null,
    isDeleted: false,
    isReadOnly: true,
    firstPublishTime: DateTimeX.epoch,
  );

  final String id;
  final String ownerId;
  final String assetUri;
  final RecordVersion version;
  final String name;
  final FormatNode formattedName;
  final String? description;
  final FormatNode? formattedDescription;
  final RecordType recordType;
  final String? ownerName;
  final List<String> tags;
  final String? path;
  final String? thumbnailUri;
  final bool isPublic;
  final bool isForPatreons;
  final bool isListed;
  final bool isDeleted;
  final bool isReadOnly;
  final DateTime lastModificationTime;
  final DateTime creationTime;
  final DateTime? firstPublishTime;
  final int visits;
  final int rating;
  final int randomOrder;
  final List<AssetManifest> assetManifest;

  Record({
    required this.id,
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
    required this.creationTime,
    required this.assetManifest,
    required this.version,
    required this.visits,
    required this.rating,
    required this.randomOrder,
    required this.ownerName,
    required this.isDeleted,
    required this.isReadOnly,
    required this.firstPublishTime,
  })  : formattedName = FormatNode.fromText(name),
        formattedDescription = FormatNode.fromText(description);


  factory Record.fromMap(Map map) {
    return Record(
      id: map["id"] ?? "0",
      ownerId: map["ownerId"] ?? "",
      assetUri: map["assetUri"] ?? "",
      name: map["name"] ?? "",
      version: RecordVersion.fromMap(map["version"]),
      description: map["description"] ?? "",
      tags: (map["tags"] as List? ?? []).map((e) => e.toString()).toList(),
      recordType: RecordType.fromName(map["recordType"]),
      thumbnailUri: map["thumbnailUri"] ?? "",
      isPublic: map["isPublic"] ?? false,
      isForPatreons: map["isForPatreons"] ?? false,
      isListed: map["isListed"] ?? false,
      lastModificationTime: DateTime.tryParse(map["lastModificationTime"] ?? "") ?? DateTimeX.epoch,
      assetManifest: (map["assetManifest"] as List? ?? []).map((e) => AssetManifest.fromMap(e)).toList(),
      creationTime: DateTime.tryParse(map["lastModificationTime"] ?? "") ?? DateTimeX.epoch,
      path: map["path"] ?? "",
      visits: map["visits"] ?? 0,
      rating: map["rating"] ?? 0,
      randomOrder: map["randomOrder"] ?? 0,
      ownerName: map["ownerName"],
      isDeleted: map["isDeleted"] ?? false,
      isReadOnly: map["isReadOnly"] ?? false,
      firstPublishTime: DateTime.tryParse(map["firstPublishTime"] ?? ""),
    );
  }

  factory Record.local({
    required String name,
    required RecordType recordType,
    required String ownerId,
    required List<AssetManifest> assetManifest,
    String assetUri = "",
  }) {
    final now = DateTime.now();
    return Record(
      id: generateId(),
      path: null,
      ownerId: ownerId,
      assetUri: assetUri,
      name: name,
      description: null,
      tags: [],
      recordType: recordType,
      thumbnailUri: null,
      isPublic: true,
      isListed: true,
      isForPatreons: false,
      lastModificationTime: now,
      creationTime: now,
      assetManifest: assetManifest,
      version: RecordVersion(
        globalVersion: 1,
        localVersion: 1,
        lastModifyingUserId: ownerId,
        lastModifyingMachineId: null,
      ),
      visits: 0,
      rating: 0,
      randomOrder: 0,
      ownerName: null,
      isDeleted: false,
      isReadOnly: false,
      firstPublishTime: null,
    );
  }

  factory Record.inventoryRoot() => _rootRecord;

  bool get isRoot => this == _rootRecord;

  bool get isLink => assetUri.startsWith("resrec");

  bool get isItem => assetUri.startsWith("resdb");

  bool get isGroupRecord => linkOwnerId.startsWith("G-");

  String get linkRecordId {
    if (!isLink) {
      throw "Record is not a link.";
    }

    final lastSlashIdx = assetUri.lastIndexOf("/");
    if (lastSlashIdx == -1) {
      throw "Record has invalid assetUri";
    }

    return assetUri.substring(lastSlashIdx + 1);
  }

  String get linkOwnerId {
    if (!assetUri.startsWith("resrec")) {
      throw "Record is not a link.";
    }

    final ownerId = assetUri.replaceFirst("resrec:///", "");

    final nextSlashIdx = ownerId.indexOf("/");
    if (nextSlashIdx == -1) {
      throw "Record has invalid assetUri";
    }

    return ownerId.substring(0, nextSlashIdx);
  }

  Record copyWith({
    String? id,
    String? ownerId,
    String? assetUri,
    RecordVersion? version,
    String? name,
    String? Function()? description,
    RecordType? recordType,
    String? Function()? ownerName,
    List<String>? tags,
    String? Function()? path,
    String? Function()? thumbnailUri,
    bool? isPublic,
    bool? isForPatreons,
    bool? isListed,
    bool? isDeleted,
    bool? isReadOnly,
    DateTime? lastModificationTime,
    DateTime? creationTime,
    DateTime? Function()? firstPublishTime,
    int? visits,
    int? rating,
    int? randomOrder,
    List<AssetManifest>? assetManifest,
  }) =>
      Record(
        id: id ?? this.id,
        path: path == null ? this.path : path(),
        ownerId: ownerId ?? this.ownerId,
        assetUri: assetUri ?? this.assetUri,
        name: name ?? this.name,
        description: description == null ? this.description : description(),
        tags: tags ?? this.tags,
        recordType: recordType ?? this.recordType,
        thumbnailUri: thumbnailUri == null ? this.thumbnailUri : thumbnailUri(),
        isPublic: isPublic ?? this.isPublic,
        isListed: isListed ?? this.isListed,
        isForPatreons: isForPatreons ?? this.isForPatreons,
        lastModificationTime: lastModificationTime ?? this.lastModificationTime,
        creationTime: creationTime ?? this.creationTime,
        assetManifest: assetManifest ?? this.assetManifest,
        version: version ?? this.version,
        visits: visits ?? this.visits,
        rating: rating ?? this.rating,
        randomOrder: randomOrder ?? this.randomOrder,
        ownerName: ownerName == null ? this.ownerName : ownerName(),
        isDeleted: isDeleted ?? this.isDeleted,
        isReadOnly: isReadOnly ?? this.isReadOnly,
        firstPublishTime: firstPublishTime == null ? this.firstPublishTime : firstPublishTime(),
      );

  Map toMap() {
    return {
      "id": id,
      "ownerId": ownerId,
      "assetUri": assetUri,
      "version": version.toMap(),
      "name": name,
      "description": description?.asNullable,
      "tags": tags,
      "recordType": recordType.name,
      "thumbnailUri": thumbnailUri?.asNullable,
      "isPublic": isPublic,
      "isForPatreons": isForPatreons,
      "isListed": isListed,
      "lastModificationTime": lastModificationTime.toUtc().toIso8601String(),
      "assetManifest": assetManifest.map((e) => e.toMap()).toList(),
      "creationTime": creationTime.toUtc().toIso8601String(),
      "path": path?.asNullable,
      "visits": visits,
      "rating": rating,
      "randomOrder": randomOrder,
      "ownerName": ownerName,
      "isDeleted": isDeleted,
      "isReadOnly": isReadOnly,
      "firstPublishTime": firstPublishTime?.toUtc().toIso8601String(),
    };
  }

  static String generateId() {
    return "R-${const Uuid().v4()}";
  }

  String? extractMessageId() {
    const key = "message_id:";
    for (final tag in tags) {
      if (tag.startsWith(key)) {
        return tag.replaceFirst(key, "");
      }
    }
    return null;
  }
}
