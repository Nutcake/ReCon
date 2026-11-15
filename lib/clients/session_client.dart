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
  bool _isLoading = false;

  bool get isLoading => _isLoading;

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
    messagingClient.sessionsRevision.addListener(notifyListeners);
  }

  SessionFilterSettings get filterSettings => _filterSettings;

  List<Session> get sessions => messagingClient.knownSessions.whereNot(shouldFilter).sorted((a, b) => b.sessionUsers.length.compareTo(a.sessionUsers.length));

  set filterSettings(SessionFilterSettings value) {
    _filterSettings = value;
    notifyListeners();
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

  Future<void> reloadSessions() async {
    _isLoading = true;
    notifyListeners();
    try {
      await messagingClient.fetchSessions();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    messagingClient.sessionsRevision.removeListener(notifyListeners);
    super.dispose();
  }
}
