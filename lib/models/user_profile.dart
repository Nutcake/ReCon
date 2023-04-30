class UserProfile {
  final String iconUrl;

  UserProfile({required this.iconUrl});

  factory UserProfile.fromMap(Map map) {
    return UserProfile(iconUrl: map["iconUrl"] ?? "");
  }

  Map toMap() {
    return {
      "iconUrl": iconUrl,
    };
  }
}