import 'package:collection/collection.dart';
import 'package:recon/apis/session_api.dart';
import 'package:recon/clients/api_client.dart';
import 'package:recon/clients/settings_client.dart';
import 'package:recon/models/session.dart';
import 'package:flutter/foundation.dart';

class SessionClient extends ChangeNotifier {
  final ApiClient apiClient;
  final SettingsClient settingsClient;

  Future<List<Session>>? _sessionsFuture;

  SessionFilterSettings _filterSettings = SessionFilterSettings.empty();

  SessionClient({required this.apiClient, required this.settingsClient}) {
    _filterSettings = SessionFilterSettings(
      name: "",
      hostName: "",
      hostId: "",
      includeEnded: settingsClient.currentSettings.sessionViewLastIncludeEnded.valueOrDefault,
      includeIncompatible: settingsClient.currentSettings.sessionViewLastIncludeIncompatible.valueOrDefault,
      minActiveUsers: settingsClient.currentSettings.sessionViewLastMinimumUsers.valueOrDefault,
      includeEmptyHeadless: settingsClient.currentSettings.sessionViewLastIncludeEmpty.valueOrDefault,
    );
  }

  SessionFilterSettings get filterSettings => _filterSettings;

  Future<List<Session>>? get sessionsFuture => _sessionsFuture;

  set filterSettings(value) {
    _filterSettings = value;
    reloadSessions();
  }

  void initSessions() {
    _sessionsFuture = SessionApi.getSessions(apiClient, filterSettings: _filterSettings).then(
          (value) => value.sorted(
            (a, b) => b.sessionUsers.length.compareTo(a.sessionUsers.length),
      ),
    );
  }

  void reloadSessions() {
    initSessions();
    notifyListeners();
  }
}
