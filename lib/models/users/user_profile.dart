class UserProfile {
  final String iconUrl;
  final String? tagline;
  //final List<EntityId> displayBadges;
  final String? description;

  UserProfile({
    required this.iconUrl,
    this.tagline, 
    this.description
  });

  factory UserProfile.empty() => UserProfile(
    iconUrl: "",
    tagline: null,
    description: null,
  );

  factory UserProfile.fromMap(Map? map) {
    return UserProfile(
      iconUrl: map?["iconUrl"] ?? ""
      tagline: map?["tagline"],
      description: map?["description"],
    );
  }

  Map toMap() {
    return {
      "iconUrl": iconUrl,
      if (tagline != null) "tagline": tagline,
      if (description != null) "description": description,
    };
  }
}