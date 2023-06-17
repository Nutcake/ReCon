import 'package:collection/collection.dart';
import 'package:contacts_plus_plus/apis/session_api.dart';
import 'package:contacts_plus_plus/clients/api_client.dart';
import 'package:contacts_plus_plus/models/session.dart';
import 'package:flutter/foundation.dart';

class SessionClient extends ChangeNotifier {
  final ApiClient apiClient;

  Future<List<Session>>? _sessionsFuture;

  SessionFilterSettings _filterSettings = SessionFilterSettings.empty();

  SessionClient({required this.apiClient});

  SessionFilterSettings get filterSettings => _filterSettings;

  Future<List<Session>>? get sessionsFuture => _sessionsFuture;

  set filterSettings(value) {
    _filterSettings = value;
    reloadSessions();
  }

  void reloadSessions() {
    _sessionsFuture = SessionApi.getSessions(apiClient, filterSettings: _filterSettings).then(
      (value) => value.sorted(
        (a, b) => b.sessionUsers.length.compareTo(a.sessionUsers.length),
      ),
    );
    notifyListeners();
  }
}
