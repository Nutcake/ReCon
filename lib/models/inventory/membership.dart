class Membership {
  final String userId;
  final String groupId;
  final String groupName;
  final bool isMigrated;

  const Membership({
    required this.userId,
    required this.groupId,
    required this.groupName,
    required this.isMigrated,
  });

  factory Membership.fromMap(Map map) => Membership(
    userId: map["ownerId"] ?? "",
    groupId: map["id"] ?? "",
    groupName: map["groupName"] ?? "",
    isMigrated: map["isMigrated"] ?? false,
  );

  Map toMap() => {
    "ownerId": userId,
    "id": groupId,
    "groupName": groupName,
    "isMigrated": isMigrated,
  };
}