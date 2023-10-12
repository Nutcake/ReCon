import 'dart:convert';

import 'package:http/http.dart' as http;

class GithubApi {
  static const baseUrl = "https://api.github.com";

  static Future<String> getLatestTagName() async {
    final response = await http.get(Uri.parse("$baseUrl/repos/Nutcake/ReCon/releases?per_page=1"));
    if (response.statusCode != 200) return "";
    final body = jsonDecode(response.body) as List;
    if (body.isEmpty) return "";
    return body.first["tag_name"] ?? "";
  }
}