import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:recon/models/authentication_data.dart';
import 'package:uuid/uuid.dart';

import '../config.dart';

class ApiClient {
  static const String totpKey = "TOTP";
  static const String userIdKey = "userId";
  static const String machineIdKey = "machineId";
  static const String tokenKey = "token";
  static const String passwordKey = "password";
  static const String uidKey = "uid";

  ApiClient({required AuthenticationData authenticationData, required this.onLogout}) : _authenticationData = authenticationData;

  final AuthenticationData _authenticationData;
  final Logger _logger = Logger("API");

  // Saving the context here feels kinda cringe ngl
  final Function() onLogout;
  final http.Client _client = http.Client();

  AuthenticationData get authenticationData => _authenticationData;

  String get userId => _authenticationData.userId;

  bool get isAuthenticated => _authenticationData.isAuthenticated;

  static Future<AuthenticationData> tryLogin({
    required String username,
    required String password,
    bool rememberMe = true,
    bool rememberPass = true,
    String? oneTimePad,
  }) async {
    final body = {
      (username.contains("@") ? "email" : "username"): username.trim(),
      "authentication": {
        r"$type": "password",
        "password": password,
      },
      "rememberMe": rememberMe,
      "secretMachineId": const Uuid().v4(),
    };
    final uid = const Uuid().v4().replaceAll("-", "");
    final response = await http.post(
      buildFullUri("/userSessions"),
      headers: {
        "Content-Type": "application/json",
        "UID": uid,
        if (oneTimePad != null) totpKey: oneTimePad,
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 403 && response.body == totpKey) {
      throw totpKey;
    }
    if (response.statusCode == 400) {
      throw "Invalid Credentials";
    }
    checkResponseCode(response);
    final data = jsonDecode(response.body) as Map;
    (data["entity"] as Map)["uid"] = uid;
    final authData = AuthenticationData.fromMap(data);
    if (authData.isAuthenticated) {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      await storage.write(key: userIdKey, value: authData.userId);
      await storage.write(key: machineIdKey, value: authData.secretMachineIdHash);
      await storage.write(key: tokenKey, value: authData.token);
      await storage.write(key: uidKey, value: authData.uid);
      if (rememberPass) await storage.write(key: passwordKey, value: password);
    }
    return authData;
  }

  static Future<AuthenticationData> tryCachedLogin() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    var userId = await storage.read(key: userIdKey);
    final machineId = await storage.read(key: machineIdKey);
    final token = await storage.read(key: tokenKey);
    final password = await storage.read(key: passwordKey);
    final uid = await storage.read(key: uidKey);

    if (userId == null || machineId == null || uid == null) {
      return AuthenticationData.unauthenticated();
    }

    if (token != null) {
      final response = await http.patch(
        buildFullUri("/userSessions"),
        headers: {
          "Authorization": "res $userId:$token",
          "UID": uid,
        },
      );
      if (response.statusCode < 300) {
        return AuthenticationData(
          userId: userId,
          token: token,
          secretMachineIdHash: machineId,
          isAuthenticated: true,
          uid: uid,
        );
      }
    }

    if (password != null) {
      try {
        userId = userId.startsWith("U-") ? userId.replaceRange(0, 2, "") : userId;
        final loginResult = await tryLogin(username: userId, password: password, rememberPass: true);
        if (loginResult.isAuthenticated) return loginResult;
      } catch (_) {
        // We don't need to notify the user if the cached login fails behind the scenes, so just ignore any exceptions.
      }
    }
    return AuthenticationData.unauthenticated();
  }

  Future<void> logout() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    await storage.delete(key: userIdKey);
    await storage.delete(key: machineIdKey);
    await storage.delete(key: tokenKey);
    await storage.delete(key: passwordKey);
    onLogout();
  }

  Future<void> extendSession() async {
    final response = await patch("/userSessions");
    if (response.statusCode != 204) {
      throw "Failed to extend session.";
    }
  }

  void checkResponse(http.Response response) {
    if (response.statusCode == 403) {
      tryCachedLogin().then((value) {
        if (!value.isAuthenticated) {
          onLogout();
        }
      });
    }
    checkResponseCode(response);
  }

  static void checkResponseCode(http.Response response) {
    if (response.statusCode < 300) return;

    final error = "${response.request?.method ?? "Unknown Method"}|${response.request?.url ?? "Unknown URL"}: ${switch (response.statusCode) {
      429 => "You are being rate limited.",
      403 => "You are not authorized to do that.",
      404 => "Resource not found.",
      500 => "Internal server error.",
      _ => "Unknown Error."
    }} (${response.statusCode}${kDebugMode && response.body.isNotEmpty ? "|${response.body}" : ""})";

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: StackTrace.current,
      ),
    );
    throw error;
  }

  Map<String, String> get authorizationHeader => _authenticationData.authorizationHeader;

  static Uri buildFullUri(String path) => Uri.parse("${Config.apiBaseUrl}$path");

  Future<http.Response> get(String path, {Map<String, String>? headers}) async {
    headers ??= {};
    headers.addAll(authorizationHeader);
    final response = await _client.get(buildFullUri(path), headers: headers);
    _logger.info("GET $path => ${response.statusCode}${response.statusCode >= 300 ? ": ${response.body}" : ""}");
    return response;
  }

  Future<http.Response> post(String path, {Object? body, Map<String, String>? headers}) async {
    headers ??= {};
    headers["Content-Type"] = "application/json";
    headers.addAll(authorizationHeader);
    final response = await _client.post(buildFullUri(path), headers: headers, body: body);
    _logger.info("PST $path => ${response.statusCode}${response.statusCode >= 300 ? ": ${response.body}" : ""}");
    return response;
  }

  Future<http.Response> put(String path, {Object? body, Map<String, String>? headers}) async {
    headers ??= {};
    headers["Content-Type"] = "application/json";
    headers.addAll(authorizationHeader);
    final response = await _client.put(buildFullUri(path), headers: headers, body: body);
    _logger.info("PUT $path => ${response.statusCode}${response.statusCode >= 300 ? ": ${response.body}" : ""}");
    return response;
  }

  Future<http.Response> delete(String path, {Map<String, String>? headers}) async {
    headers ??= {};
    headers.addAll(authorizationHeader);
    final response = await _client.delete(buildFullUri(path), headers: headers);
    _logger.info("DEL $path => ${response.statusCode}${response.statusCode >= 300 ? ": ${response.body}" : ""}");
    return response;
  }

  Future<http.Response> patch(String path, {Object? body, Map<String, String>? headers}) async {
    headers ??= {};
    headers["Content-Type"] = "application/json";
    headers.addAll(authorizationHeader);
    final response = await _client.patch(buildFullUri(path), headers: headers, body: body);
    _logger.info("PAT $path => ${response.statusCode}${response.statusCode >= 300 ? ": ${response.body}" : ""}");
    return response;
  }
}
