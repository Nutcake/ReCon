class Session {
  final String id;
  final String name;
  final List<SessionUser> sessionUsers;
  final String thumbnail;
  final int maxUsers;
  final bool hasEnded;
  final bool isValid;
  final String description;
  final List<String> tags;
  final bool headlessHost;

  Session({required this.id, required this.name, required this.sessionUsers, required this.thumbnail,
    required this.maxUsers, required this.hasEnded, required this.isValid, required this.description,
    required this.tags, required this.headlessHost,
  });

  factory Session.fromMap(Map map) {
    return Session(
      id: map["sessionId"],
      name: map["name"],
      sessionUsers: (map["sessionUsers"] as List? ?? []).map((entry) => SessionUser.fromMap(entry)).toList(),
      thumbnail: map["thumbnail"] ?? "",
      maxUsers: map["maxUsers"],
      hasEnded: map["hasEnded"],
      isValid: map["isValid"],
      description: map["description"] ?? "",
      tags: ((map["tags"] as List?) ?? []).map((e) => e.toString()).toList(),
      headlessHost: map["headlessHost"],
    );
  }

  bool get isLive => !hasEnded && isValid;
}

class SessionUser {
  final String id;
  final String username;
  final bool isPresent;
  final int outputDevice;

  SessionUser({required this.id, required this.username, required this.isPresent, required this.outputDevice});

  factory SessionUser.fromMap(Map map) {
    return SessionUser(
      id: map["userID"],
      username: map["username"],
      isPresent: map["isPresent"],
      outputDevice: map["outputDevice"],
    );
  }
}