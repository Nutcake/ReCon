import 'dart:convert';

import 'package:contacts_plus_plus/models/settings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class SettingsClient {
  static const String _settingsKey = "settings";
  static const _storage = FlutterSecureStorage();
  final List<Future<void> Function(Settings oldSettings, Settings newSettings)> _listeners = [];
  Settings _currentSettings = Settings();

  void addListener(Future<void> Function(Settings oldSettings, Settings newSettings) listener) {
    _listeners.add(listener);
  }

  Future<void> notifyListeners(Settings oldSettings, Settings newSettings) async {
    for(final listener in _listeners) {
      await listener.call(oldSettings, newSettings);
    }
  }

  Settings get currentSettings => _currentSettings;

  Future<void> loadSettings() async {
    final data = await _storage.read(key: _settingsKey);
    if (data == null) return;
    _currentSettings = Settings.fromMap(jsonDecode(data));
  }

  Future<void> changeSettings(Settings newSettings) async {
    await _storage.write(key: _settingsKey, value: jsonEncode(newSettings.toMap()));
    await notifyListeners(_currentSettings, newSettings);
    _currentSettings = newSettings;
  }
}