import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:recon/apis/session_api.dart';
import 'package:recon/clients/api_client.dart';
import 'package:recon/clients/messaging_client.dart';
import 'package:recon/clients/settings_client.dart';
import 'package:recon/models/session.dart';

class SessionClient extends ChangeNotifier {
  final ApiClient apiClient;
  final SettingsClient settingsClient;
  final MessagingClient messagingClient;

  Future<List<Session>>? _sessionsFuture;

  SessionFilterSettings _filterSettings = SessionFilterSettings.empty();

  SessionClient({required this.apiClient, required this.messagingClient, required this.settingsClient}) {
    _filterSettings = SessionFilterSettings(
      name: "",
      hostName: "",
      includeEnded: settingsClient.currentSettings.sessionViewLastIncludeEnded.valueOrDefault,
      includeIncompatible: settingsClient.currentSettings.sessionViewLastIncludeIncompatible.valueOrDefault,
      minActiveUsers: settingsClient.currentSettings.sessionViewLastMinimumUsers.valueOrDefault,
      includeEmptyHeadless: settingsClient.currentSettings.sessionViewLastIncludeEmpty.valueOrDefault,
    );
    _sessionsFuture = Future.value(messagingClient.knownSessions)
      ..whenComplete(() async {
        notifyListeners();
        await Future.delayed(const Duration(seconds: 1)); // need this or the API get's mad at me :c
        reloadSessions();
      });
  }

  SessionFilterSettings get filterSettings => _filterSettings;

  Future<List<Session>>? get sessionsFuture => _sessionsFuture;

  set filterSettings(SessionFilterSettings value) {
    if (value.includeEmptyHeadless != _filterSettings.includeEmptyHeadless) {
      _filterSettings = value;
      reloadSessions();
    } else {
      _filterSettings = value;
      notifyListeners();
    }
  }

  bool shouldFilter(Session session) {
    if (session.id == null) {
      return true;
    }
    if (filterSettings.name.isNotEmpty) {
      if (!session.name.contains(filterSettings.name)) {
        return true;
      }
    }
    if (filterSettings.hostName.isNotEmpty) {
      if (!session.hostUsername.contains(filterSettings.hostName)) {
        return true;
      }
    }
    if (!filterSettings.includeEnded) {
      if (session.hasEnded) {
        return true;
      }
    }
    if (!filterSettings.includeEmptyHeadless) {
      if (session.headlessHost && session.totalJoinedUsers <= 1) {
        return true;
      }
    }
    if (filterSettings.minActiveUsers > 0) {
      if (session.totalActiveUsers < filterSettings.minActiveUsers) {
        return true;
      }
    }
    return false;
  }

  void initSessions() {
    _sessionsFuture = SessionApi.getSessions(
      apiClient,
      filterSettings: _filterSettings,
    ).then((value) => value.sorted((a, b) => b.sessionUsers.length.compareTo(a.sessionUsers.length)));
  }

  void reloadSessions() {
    initSessions();
    notifyListeners();
  }
}
