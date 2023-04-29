import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:contacts_plus/models/authentication_data.dart';
import 'package:uuid/uuid.dart';

import 'config.dart';

class ApiClient {
  static const String userIdKey = "userId";
  static const String machineIdKey = "machineId";
  static const String tokenKey = "token";

  final AuthenticationData _authenticationData;

  const ApiClient({required AuthenticationData authenticationData}) : _authenticationData = authenticationData;

  static Future<AuthenticationData> tryLogin({required String username, required String password, bool rememberMe=false}) async {
    final body = {
      "username": username,
      "password": password,
      "rememberMe": rememberMe,
      "secretMachineId": const Uuid().v4(),
    };
    final response = await http.post(
        Uri.parse("${Config.apiBaseUrl}/api/UserSessions"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body));
    if (response.statusCode == 400) {
      throw "Invalid Credentials";
    } else if (response.statusCode != 200) {
      throw "Unknown Error${kDebugMode ? ": ${response.statusCode}|${response.body}" : ""}";
    }

    final authData = AuthenticationData.fromJson(jsonDecode(response.body));
    if (authData.isAuthenticated) {
      const FlutterSecureStorage storage = FlutterSecureStorage();
      await storage.write(key: userIdKey, value: authData.userId);
      await storage.write(key: machineIdKey, value: authData.secretMachineId);
      await storage.write(key: tokenKey, value: authData.token);
    }
    return authData;
  }

  static Future<AuthenticationData> tryCachedLogin() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    String? userId = await storage.read(key: userIdKey);
    String? machineId = await storage.read(key: machineIdKey);
    String? token = await storage.read(key: tokenKey);

    if (userId == null || machineId == null || token == null) {
      return AuthenticationData.unauthenticated();
    }

    final response = await http.get(Uri.parse("${Config.apiBaseUrl}/api/users/$userId"), headers: {
      "Authorization": "neos $userId:$token"
    });
    if (response.statusCode == 200) {
      return AuthenticationData(userId: userId, token: token, secretMachineId: machineId, isAuthenticated: true);
    }
    return AuthenticationData.unauthenticated();
  }

  Map<String, String> get authorizationHeader => {
    "Authorization": "neos ${_authenticationData.userId}:${_authenticationData.token}"
  };

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) {
    headers ??= {};
    headers.addAll(authorizationHeader);
    return http.get(uri, headers: headers);
  }

  Future<http.Response> post(Uri uri, {Object? body, Map<String, String>? headers}) {
    headers ??= {};
    headers["Content-Type"] = "application/json";
    headers.addAll(authorizationHeader);
    return http.post(uri, headers: headers, body: body);
  }

  Future<http.Response> put(Uri uri, {Object? body, Map<String, String>? headers}) {
    headers ??= {};
    headers.addAll(authorizationHeader);
    return http.put(uri, headers: headers, body: body);
  }

  Future<http.Response> delete(Uri uri, {Map<String, String>? headers}) {
    headers ??= {};
    headers.addAll(authorizationHeader);
    return http.delete(uri, headers: headers);
  }
}