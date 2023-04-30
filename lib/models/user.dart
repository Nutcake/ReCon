import 'package:contacts_plus/models/user_profile.dart';

class User {
  final String id;
  final String username;
  final DateTime registrationDate;
  final UserProfile? userProfile;

  const User({required this.id, required this.username, required this.registrationDate, this.userProfile});

  factory User.fromMap(Map map) {
    UserProfile? profile;
    try {
      profile = UserProfile.fromMap(map["profile"]);
    } catch (e) {
      profile = null;
    }
    return User(
      id: map["id"],
      username: map["username"],
      registrationDate: DateTime.parse(map["registrationDate"]),
      userProfile: profile,
    );
  }
}