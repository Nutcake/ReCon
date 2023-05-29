enum FriendStatus {
  none,
  searchResult,
  requested,
  ignored,
  blocked,
  accepted;

  factory FriendStatus.fromString(String text) {
    return FriendStatus.values.firstWhere((element) => element.name.toLowerCase() == text.toLowerCase(),
      orElse: () => FriendStatus.none,
    );
  }
}
