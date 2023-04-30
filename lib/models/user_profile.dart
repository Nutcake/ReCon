import 'package:contacts_plus/config.dart';

class UserProfile {
  final String iconUrl;

  UserProfile({required this.iconUrl});

  factory UserProfile.fromMap(Map map) {
    return UserProfile(iconUrl: map["iconUrl"]);
  }

  Uri get httpIconUri {
    final fullUri = iconUrl.replaceFirst("neosdb:///", Config.neosCdnUrl);
    final lastPeriodIndex = fullUri.lastIndexOf(".");
    if (lastPeriodIndex != -1 && fullUri.length - lastPeriodIndex < 8) {
      return Uri.parse(fullUri.substring(0, lastPeriodIndex));
    }
    return Uri.parse(fullUri);
  }
}