import 'dart:convert';
import 'dart:developer';
import 'package:contacts_plus/models/message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:contacts_plus/models/authentication_data.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:signalr_netcore/ihub_protocol.dart';
import 'package:signalr_netcore/msgpack_hub_protocol.dart';
import 'package:signalr_netcore/web_supporting_http_client.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';

import 'config.dart';

class ApiClient {
  static const String userIdKey = "userId";
  static const String machineIdKey = "machineId";
  static const String tokenKey = "token";
  static const String passwordKey = "password";

  ApiClient({required AuthenticationData authenticationData}) : _authenticationData = authenticationData {
    if (_authenticationData.isAuthenticated) {
      hub.start();
    }
  }

  late final NeosHub hub = NeosHub(token: authorizationHeader.values.first);
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
    if (response.statusCode != 200) {
      throw "Unknown Error${kDebugMode ? ": ${response.statusCode}|${response.body}" : ""}";
    }
  }

  Map<String, String> get authorizationHeader => {
    "Authorization": "neos ${_authenticationData.userId}:${_authenticationData.token}"
  };

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

class NeosHub {
  late final HubConnection hubConnection;
  final Logger _logger = Logger("NeosHub");

  NeosHub({required String token}) {
    hubConnection = HubConnectionBuilder()
        .withUrl(
      Config.neosHubUrl,
      options: HttpConnectionOptions(
          headers: MessageHeaders()
            ..setHeaderValue("Authorization", token),
          httpClient: WebSupportingHttpClient(
            _logger,
          ),
          logger: _logger,
          logMessageContent: true
      ),
    ).withAutomaticReconnect().build();
    hubConnection.onreconnecting(({error}) {
      log("onreconnecting called with error $error");
    });
    hubConnection.onreconnected(({connectionId}) {
      log("onreconnected called");
    });
  }

  void start() {
    hubConnection.start()?.onError((error, stackTrace) => log(error.toString())).whenComplete(() {
      log("Hub connection established");
    });
  }

  Future<void> sendMessage(Message message) async {
    await hubConnection.send("SendMessage", args: [message.toMap()]);
  }
}
