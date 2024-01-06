enum ContactStatus {
  none,
  searchResult,
  requested,
  ignored,
  blocked,
  accepted;

  factory ContactStatus.fromString(String text) {
    return ContactStatus.values.firstWhere((element) => element.name.toLowerCase() == text.toLowerCase(),
      orElse: () => ContactStatus.none,
    );
  }
}
