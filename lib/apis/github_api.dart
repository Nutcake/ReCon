import 'dart:convert';

import 'package:http/http.dart' as http;

class GithubApi {
  static const baseUrl = "https://api.github.com";

  static Future<String> getLatestTagName() async {
    final response = await http.get(Uri.parse("$baseUrl/repos/Nutcake/contacts-plus-plus/releases/latest"));
    if (response.statusCode != 200) return "";
    final body = jsonDecode(response.body);
    return body["tag_name"] ?? "";
  }
}