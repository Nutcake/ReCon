import 'package:recon/string_formatter.dart';

class Session {
  final String name;
  final FormatNode formattedName;
  final String description;
  final FormatNode formattedDescription;
  final List<String> tags;
  final String id; //sessionId
  final String hostUserId;
  final String hostMachineId;
  final String hostUsername;
  final String universeId;
  final String appVersion;
  final bool headlessHost;
  final List<String> sessionURLs;
  final List<SessionUser> sessionUsers;
  final String thumbnailUrl;
  final int joinedUsers;
  final int minActiveUsers;
  final int totalJoinedUsers;
  final int totalActiveUsers;
  final int maxUsers;
  final bool mobileFriendly;
  final DateTime sessionBeginTime;
  final DateTime lastUpdate;
  final SessionAccessLevel accessLevel;
  final bool hideFromListing;
  final String broadcastKey;
  final bool awayKickEnabled;
  //final Float awayKickMinutes;
  final bool hasEnded;
  final bool isValid;

  Session({
    required this.name,
    required this.description,
    required this.tags,
    required this.id,
    required this.hostUserId,
    required this.hostMachineId,
    required this.hostUsername,
    required this.universeId,
    required this.appVersion,
    required this.headlessHost,
    required this.sessionURLs,
    required this.sessionUsers,
    required this.thumbnailUrl,
    required this.joinedUsers,
    required this.minActiveUsers,
    required this.totalJoinedUsers,
    required this.totalActiveUsers,
    required this.maxUsers,
    required this.mobileFriendly,
    required this.sessionBeginTime,
    required this.lastUpdate,
    required this.accessLevel,
    required this.hideFromListing,
    required this.broadcastKey,
    required this.awayKickEnabled,
    required this.hasEnded,
    required this.isValid,
    
  })  : formattedName = FormatNode.fromText(name),
        formattedDescription = FormatNode.fromText(description);

  factory Session.none() {
    return Session(
      name: "",
      description: "",
      tags: const [],
      id: "",
      hostUserId: "",
      hostMachineId: "",
      hostUsername: "",
      universeId: "",
      appVersion: "",
      headlessHost: false,
      sessionURLs: const [],
      sessionUsers: const [],
      thumbnailUrl: "",
      joinedUsers: 0,
      minActiveUsers: 0,
      totalJoinedUsers: 0,
      totalActiveUsers: 0,
      maxUsers: 0,
      mobileFriendly: false,
      sessionBeginTime: DateTime.now(),
      lastUpdate: DateTime.now(),
      accessLevel: SessionAccessLevel.unknown,
      hideFromListing: false,
      broadcastKey: "",
      awayKickEnabled: false,
      hasEnded: true,
      isValid: false,
    );
  }

  bool get isVisible => name.isNotEmpty && accessLevel != SessionAccessLevel.unknown;

  factory Session.fromMap(Map? map) {
    if (map == null) return Session.none();
    return Session(
      name: map["name"],
      description: map["description"] ?? "",
      tags: ((map["tags"] as List?) ?? []).map((e) => e.toString()).toList(),
      id: map["sessionId"],
      hostUserId: map["hostUserId"] ?? "",
      hostMachineId: map["hostMachineId"] ?? "",
      hostUsername: map["hostUsername"] ?? "",
      universeId: map["universeId"] ?? "",
      appVersion: map["appVersion"] ?? "",
      headlessHost: map["headlessHost"] ?? false,
      sessionURLs: (map["sessionURLs"] as List? ?? []).map((e) => e.toString()).toList(),
      sessionUsers: (map["sessionUsers"] as List? ?? []).map((entry) => SessionUser.fromMap(entry)).toList(),
      thumbnailUrl: map["thumbnailUrl"] ?? "",
      joinedUsers: map["joinedUsers"] ?? 0,
      minActiveUsers: map["minActiveUsers"] ?? 0,
      totalJoinedUsers: map["totalJoinedUsers"] ?? 0,
      totalActiveUsers: map["totalActiveUsers"] ?? 0,
      maxUsers: map["maxUsers"] ?? 0,
      mobileFriendly: map["mobileFriendly"] ?? false,
      sessionBeginTime: DateTime.tryParse(map["sessionBeginTime"] ?? "") ?? DateTime.now(),
      lastUpdate: DateTime.tryParse(map["lastUpdate"] ?? "") ?? DateTime.now(),
      accessLevel: SessionAccessLevel.fromName(map["accessLevel"]),
      hideFromListing: map["hideFromListing"] ?? false,
      broadcastKey: map["broadcastKey"] ?? "",
      awayKickEnabled: map["awayKickEnabled"] ?? false,
      hasEnded: map["hasEnded"] ?? false,
      isValid: map["isValid"] ?? true,
    );
  }

  Map toMap({bool shallow = false}) {
    return {
      "name": name,
      "description": description,
      "tags": shallow ? [] : tags,
      "sessionId": id,
      "hostUserId": hostUserId,
      "hostMachineId": hostMachineId,
      "hostUsername": hostUsername,
      "universeId": universeId,
      "appVersion": appVersion,
      "headlessHost": headlessHost,
      "sessionURLs": shallow ? [] : sessionURLs,
      "sessionUsers": shallow ? [] : sessionUsers.map((e) => e.toMap()).toList(),
      "thumbnailUrl": thumbnailUrl,
      "joinedUsers": joinedUsers,
      "minActiveUsers": minActiveUsers,
      "totalJoinedUsers": totalJoinedUsers,
      "totalActiveUsers": totalActiveUsers,
      "maxUsers": maxUsers,
      "mobileFriendly": mobileFriendly,
      "sessionBeginTime": sessionBeginTime.toIso8601String(),
      "lastUpdate": lastUpdate.toIso8601String(),
      "accessLevel": accessLevel.name, // This probably wont work, the API usually expects integers.
      "hideFromListing": hideFromListing,
      "broadcastKey": broadcastKey,
      "awayKickEnabled": awayKickEnabled,
      "hasEnded": hasEnded,
      "isValid": isValid,
    };
  }

  Session copyWith({
    String? name,
    FormatNode? formattedName,
    String? description,
    FormatNode? formattedDescription,
    List<String>? tags,
    String? id,
    String? hostUserId,
    String? hostMachineId,
    String? hostUsername,
    String? universeId,
    String? appVersion,
    bool? headlessHost,
    List<String>? sessionURLs,
    List<SessionUser>? sessionUsers,
    String? thumbnailUrl,
    int? joinedUsers,
    int? minActiveUsers,
    int? totalJoinedUsers,
    int? totalActiveUsers,
    int? maxUsers,
    bool? mobileFriendly,
    DateTime? sessionBeginTime,
    DateTime? lastUpdate,
    SessionAccessLevel? accessLevel,
    bool? hideFromListing,
    String? broadcastKey,
    bool? awayKickEnabled,
    bool? hasEnded,
    bool? isValid,
  }) {
    return Session(
      name: name ?? this.name,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      id: id ?? this.id,
      hostUserId: hostUserId ?? this.hostUserId,
      hostMachineId: hostMachineId ?? this.hostMachineId,
      hostUsername: hostUsername ?? this.hostUsername,
      universeId: universeId ?? this.universeId,
      appVersion: appVersion ?? this.appVersion,
      headlessHost: headlessHost ?? this.headlessHost,
      sessionURLs: sessionURLs ?? this.sessionURLs,
      sessionUsers: sessionUsers ?? this.sessionUsers,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      joinedUsers: joinedUsers ?? this.joinedUsers,
      minActiveUsers: minActiveUsers ?? this.minActiveUsers,
      totalJoinedUsers: totalJoinedUsers ?? this.totalJoinedUsers,
      totalActiveUsers: totalActiveUsers ?? this.totalActiveUsers,
      maxUsers: maxUsers ?? this.maxUsers,
      mobileFriendly: mobileFriendly ?? this.mobileFriendly,
      sessionBeginTime: sessionBeginTime ?? this.sessionBeginTime,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      accessLevel: accessLevel ?? this.accessLevel,
      hideFromListing: hideFromListing ?? this.hideFromListing,
      broadcastKey: broadcastKey ?? this.broadcastKey,
      awayKickEnabled: awayKickEnabled ?? this.awayKickEnabled,
      hasEnded: hasEnded ?? this.hasEnded,
      isValid: isValid ?? this.isValid,
    );
  }

  bool get isLive => !hasEnded && isValid;
}

enum SessionAccessLevel {
  unknown,
  private,
  lan,
  contacts,
  contactsPlus,
  registeredUsers,
  anyone;

  static const _readableNamesMap = {
    SessionAccessLevel.unknown: "Unknown",
    SessionAccessLevel.private: "Private",
    SessionAccessLevel.lan: "LAN",
    SessionAccessLevel.contacts: "Contacts only",
    SessionAccessLevel.contactsPlus: "Contacts+",
    SessionAccessLevel.registeredUsers: "Registered users",
    SessionAccessLevel.anyone: "Public",
  };

  factory SessionAccessLevel.fromName(String? name) {
    return SessionAccessLevel.values.firstWhere(
      (element) => element.name.toLowerCase() == name?.toLowerCase(),
      orElse: () => SessionAccessLevel.unknown,
    );
  }

  String toReadableString() {
    return SessionAccessLevel._readableNamesMap[this] ?? SessionAccessLevel.unknown.toReadableString();
  }
}

class SessionUser {
  final String id;
  final String username;
  final bool isPresent;
  final int outputDevice;

  SessionUser({required this.id, required this.username, required this.isPresent, required this.outputDevice});

  factory SessionUser.fromMap(Map map) {
    return SessionUser(
      id: map["userID"] ?? "",
      username: map["username"] ?? "Unknown",
      isPresent: map["isPresent"] ?? false,
      outputDevice: map["outputDevice"] ?? 0,
    );
  }

  Map toMap() {
    return {
      "userID": id,
      "username": username,
      "isPresent": isPresent,
      "outputDevice": outputDevice,
    };
  }
}

class SessionFilterSettings {
  final String name;
  final bool includeEnded;
  final bool includeIncompatible;
  final String hostName;
  final int minActiveUsers;
  final bool includeEmptyHeadless;

  const SessionFilterSettings({
    required this.name,
    required this.includeEnded,
    required this.includeIncompatible,
    required this.hostName,
    required this.minActiveUsers,
    required this.includeEmptyHeadless,
  });

  factory SessionFilterSettings.empty() => const SessionFilterSettings(
        name: "",
        includeEnded: false,
        includeIncompatible: false,
        hostName: "",
        minActiveUsers: 0,
        includeEmptyHeadless: true,
      );

  String buildRequestString() => "?includeEmptyHeadless=$includeEmptyHeadless"
      "${"&includeEnded=$includeEnded"}"
      "${name.isNotEmpty ? "&name=$name" : ""}"
      "${hostName.isNotEmpty ? (hostName.startsWith("U-") ? "&hostId=$hostName" : "&hostName=$hostName") : ""}"
      "${minActiveUsers > 0 ? "&minActiveUsers=$minActiveUsers" : ""}";

  SessionFilterSettings copyWith({
    String? name,
    bool? includeEnded,
    bool? includeIncompatible,
    String? hostName,
    int? minActiveUsers,
    bool? includeEmptyHeadless,
  }) {
    return SessionFilterSettings(
      name: name ?? this.name,
      includeEnded: includeEnded ?? this.includeEnded,
      includeIncompatible: includeIncompatible ?? this.includeIncompatible,
      hostName: hostName ?? this.hostName,
      minActiveUsers: minActiveUsers ?? this.minActiveUsers,
      includeEmptyHeadless: includeEmptyHeadless ?? this.includeEmptyHeadless,
    );
  }
}
