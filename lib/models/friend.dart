class Friend {
  final String id;
  final String username;
  final UserStatus userStatus;

  Friend({required this.id, required this.username, required this.userStatus});
}

enum OnlineStatus {
  offline,
  online,
}

class UserStatus {
  final OnlineStatus onlineStatus;
  final DateTime lastStatusChange;

  UserStatus({required this.onlineStatus, required this.lastStatusChange});
}