class UserProfile {
  final String iconUrl;
  final String tagline;
  final String description;
  final List<String> displayBadges;

  UserProfile({
    required this.iconUrl,
    required this.tagline,
    required this.description,
    required this.displayBadges,
  });

  factory UserProfile.empty() => UserProfile(
        iconUrl: "",
        tagline: "",
        description: "",
        displayBadges: [],
      );

  factory UserProfile.fromMap(Map? map) {
    return UserProfile(
      iconUrl: map?["iconUrl"] ?? "",
      tagline: map?["tagline"] ?? "",
      description: map?["description"] ?? "",
      displayBadges: map?["displayBadges"]?.cast<String>() ?? [],
    );
  }

  Map toMap() {
    return {
      "iconUrl": iconUrl,
      "tagline": tagline,
      "description": description,
      "displayBadges": displayBadges,
    };
  }
}
