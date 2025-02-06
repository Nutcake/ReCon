import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:recon/models/settings.dart';

class SettingsClient {
  static const String _settingsKey = "settings";
  static const _storage = FlutterSecureStorage();
  Settings _currentSettings = Settings();

  Settings get currentSettings => _currentSettings;

  Future<void> loadSettings() async {
    final data = await _storage.read(key: _settingsKey);
    if (data == null) return;
    _currentSettings = Settings.fromMap(jsonDecode(data));
  }

  Future<void> changeSettings(Settings newSettings) async {
    _currentSettings = newSettings;
    await _storage.write(key: _settingsKey, value: jsonEncode(newSettings.toMap()));
  }
}
