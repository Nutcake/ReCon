import 'dart:async';
import 'dart:convert';
import 'package:contacts_plus_plus/neos_hub.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:contacts_plus_plus/models/authentication_data.dart';
import 'package:uuid/uuid.dart';

import 'config.dart';

class ApiClient {
  static const String userIdKey = "userId";
  static const String machineIdKey = "machineId";
  static const String tokenKey = "token";
  static const String passwordKey = "password";

  ApiClient({required AuthenticationData authenticationData}) : _authenticationData = authenticationData;

  final AuthenticationData _authenticationData;

  String get userId => _authenticationData.userId;
  bool get isAuthenticated => _authenticationData.isAuthenticated;

  static Future<AuthenticationData> tryLogin({
    required String username,
    required String password,
    bool rememberMe=true,
    bool rememberPass=false
  }) async {
    final body = {
      "username": username,
      "password": password,
      "rememberMe": rememberMe,
      "secretMachineId": const Uuid().v4(),
    };
    final response = await http.post(
        buildFullUri("/UserSessions"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body));
    if (response.statusCode == 400) {
      throw "Invalid Credentials";
    } 
    checkResponse(response);

    final authData = AuthenticationData.fromMap(jsonDecode(response.body));
    if (authData.isAuthenticated) {
      const FlutterSecureStorage storage = FlutterSecureStorage();
      await storage.write(key: userIdKey, value: authData.userId);
      await storage.write(key: machineIdKey, value: authData.secretMachineId);
      await storage.write(key: tokenKey, value: authData.token);
      if (rememberPass) await storage.write(key: passwordKey, value: password);
    }
    return authData;
  }

  static Future<AuthenticationData> tryCachedLogin() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    String? userId = await storage.read(key: userIdKey);
    String? machineId = await storage.read(key: machineIdKey);
    String? token = await storage.read(key: tokenKey);
    String? password = await storage.read(key: passwordKey);

    if (userId == null || machineId == null) {
      return AuthenticationData.unauthenticated();
    }

    if (token != null) {
      final response = await http.get(buildFullUri("/users/$userId"), headers: {
        "Authorization": "neos $userId:$token"
      });
      if (response.statusCode == 200) {
        return AuthenticationData(userId: userId, token: token, secretMachineId: machineId, isAuthenticated: true);
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
  
  static void checkResponse(http.Response response) {
    if (response.statusCode == 429) {
      throw "Sorry, you are being rate limited";
    }
    if (response.statusCode == 403) {
      tryCachedLogin();
      // TODO: Show the login screen again if cached login was unsuccessful.
      throw "You are not authorized to do that.";
    }
    if (response.statusCode != 200) {
      throw "Unknown Error${kDebugMode ? ": ${response.statusCode}|${response.body}" : ""}";
    }
  }

  Map<String, String> get authorizationHeader => _authenticationData.authorizationHeader;

  static Uri buildFullUri(String path) => Uri.parse("${Config.apiBaseUrl}/api$path");

  Future<http.Response> get(String path, {Map<String, String>? headers}) {
    headers ??= {};
    headers.addAll(authorizationHeader);
    return http.get(buildFullUri(path), headers: headers);
  }

  Future<http.Response> post(String path, {Object? body, Map<String, String>? headers}) {
    headers ??= {};
    headers["Content-Type"] = "application/json";
    headers.addAll(authorizationHeader);
    return http.post(buildFullUri(path), headers: headers, body: body);
  }

  Future<http.Response> put(String path, {Object? body, Map<String, String>? headers}) {
    headers ??= {};
    headers.addAll(authorizationHeader);
    return http.put(buildFullUri(path), headers: headers, body: body);
  }

  Future<http.Response> delete(String path, {Map<String, String>? headers}) {
    headers ??= {};
    headers.addAll(authorizationHeader);
    return http.delete(buildFullUri(path), headers: headers);
  }
}

class ClientHolder extends InheritedWidget {
  final ApiClient client;
  late final NeosHub hub;

  ClientHolder({super.key, required AuthenticationData authenticationData, required super.child})
      : client = ApiClient(authenticationData: authenticationData) {
    hub = NeosHub(apiClient: client);
  }


  static ClientHolder? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ClientHolder>();
  }

  static ClientHolder of(BuildContext context) {
    final ClientHolder? result = maybeOf(context);
    assert(result != null, 'No AuthenticatedClient found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant ClientHolder oldWidget) => oldWidget.client != client;
}
