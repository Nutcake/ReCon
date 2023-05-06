import 'dart:convert';

import 'package:http/http.dart' as http;

class SemVer {
  final int major;
  final int minor;
  final int patch;

  SemVer({required this.major, required this.minor, required this.patch});

  factory SemVer.fromString(String str) {
    final split = str.split(".");
    if (split.length != 3) {
      throw "Invalid version format";
    }
    return SemVer(major: int.parse(split[0]), minor: int.parse(split[1]), patch: int.parse(split[2]));
  }


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemVer &&
          runtimeType == other.runtimeType &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch;

  @override
  int get hashCode => major.hashCode ^ minor.hashCode ^ patch.hashCode;

  bool operator >(SemVer other) {
    if (major > other.major || (major == other.major && minor > other.minor) || (major == other.major && minor == other.minor && patch > other.patch)) {
      return true;
    }
    return false;
  }
}

class GithubApi {
  static const baseUrl = "https://api.github.com";

  static Future<String> getLatestTagName() async {
    final response = await http.get(Uri.parse("$baseUrl/repos/Nutcake/contacts-plus-plus/releases/latest"));
    if (response.statusCode != 200) return "";
    final body = jsonDecode(response.body);
    return body["tag_name"] ?? "";
  }
}