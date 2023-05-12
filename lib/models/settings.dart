import 'dart:convert';

import 'package:contacts_plus_plus/models/friend.dart';
import 'package:contacts_plus_plus/models/sem_ver.dart';

class SettingsEntry<T> {
  final T? value;
  final T deflt;

  const SettingsEntry({this.value, required this.deflt});

  factory SettingsEntry.fromMap(Map map) {
    return SettingsEntry<T>(
      value: jsonDecode(map["value"]) as T?,
      deflt: map["default"],
    );
  }

  Map toMap() {
    return {
      "value": jsonEncode(value),
      "default": deflt,
    };
  }

  T get valueOrDefault => value ?? deflt;

  SettingsEntry<T> withValue({required T newValue}) => SettingsEntry(value: newValue, deflt: deflt);

  SettingsEntry<T> passThrough(T? newValue) {
    return newValue == null ? this : this.withValue(newValue: newValue);
  }
}

class Settings {
  final SettingsEntry<bool> notificationsDenied;
  final SettingsEntry<int> lastOnlineStatus;
  final SettingsEntry<String> lastDismissedVersion;

  Settings({
    SettingsEntry<bool>? notificationsDenied,
    SettingsEntry<int>? lastOnlineStatus,
    SettingsEntry<String>? lastDismissedVersion
  })
      : notificationsDenied = notificationsDenied ?? const SettingsEntry<bool>(deflt: false),
        lastOnlineStatus = lastOnlineStatus ?? SettingsEntry<int>(deflt: OnlineStatus.online.index),
        lastDismissedVersion = lastDismissedVersion ?? SettingsEntry<String>(deflt: SemVer.zero().toString())
  ;

  factory Settings.fromMap(Map map) {
    return Settings(
      notificationsDenied: retrieveEntryOrNull<bool>(map["notificationsDenied"]),
      lastOnlineStatus: retrieveEntryOrNull<int>(map["lastOnlineStatus"]),
      lastDismissedVersion: retrieveEntryOrNull<String>(map["lastDismissedVersion"])
    );
  }

  static SettingsEntry<T>? retrieveEntryOrNull<T>(Map? map) {
    if (map == null) return null;
    try {
      return SettingsEntry<T>.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Map toMap() {
    return {
      "notificationsDenied": notificationsDenied.toMap(),
      "lastOnlineStatus": lastOnlineStatus.toMap(),
      "lastDismissedVersion": lastDismissedVersion.toMap(),
    };
  }

  Settings copy() => copyWith();

  Settings copyWith({
    bool? notificationsDenied,
    int? unreadCheckIntervalMinutes,
    int? lastOnlineStatus,
    String? lastDismissedVersion,
  }) {
    return Settings(
      notificationsDenied: this.notificationsDenied.passThrough(notificationsDenied),
      lastOnlineStatus: this.lastOnlineStatus.passThrough(lastOnlineStatus),
      lastDismissedVersion: this.lastDismissedVersion.passThrough(lastDismissedVersion),
    );
  }
}