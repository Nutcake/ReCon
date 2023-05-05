import 'dart:convert';

import 'package:contacts_plus_plus/models/friend.dart';

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
      "value": value.toString(),
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
  final SettingsEntry<int> unreadCheckIntervalMinutes;
  final SettingsEntry<int> lastOnlineStatus;

  Settings({
    SettingsEntry<bool>? notificationsDenied,
    SettingsEntry<int>? unreadCheckIntervalMinutes,
    SettingsEntry<int>? lastOnlineStatus,
  }) : notificationsDenied = notificationsDenied ?? const SettingsEntry(deflt: false),
        unreadCheckIntervalMinutes = unreadCheckIntervalMinutes ?? const SettingsEntry(deflt: 60),
        lastOnlineStatus = lastOnlineStatus ?? SettingsEntry(deflt: OnlineStatus.online.index);

  factory Settings.fromMap(Map map) {
    return Settings(
      notificationsDenied: retrieveEntryOrNull<bool>(map["notificationsDenied"]),
      unreadCheckIntervalMinutes: retrieveEntryOrNull<int>(map["unreadCheckIntervalMinutes"]),
      lastOnlineStatus: retrieveEntryOrNull<int>(map["lastOnlineStatus"]),
    );
  }

  static SettingsEntry<T>? retrieveEntryOrNull<T>(Map? map) {
    if (map == null) return null;
    return SettingsEntry<T>.fromMap(map);
  }

  Map toMap() {
    return {
      "notificationsDenied": notificationsDenied.toMap(),
      "unreadCheckIntervalMinutes": unreadCheckIntervalMinutes.toMap(),
      "lastOnlineStatus": lastOnlineStatus.toMap(),
    };
  }

  Settings copy() => copyWith();

  Settings copyWith({bool? notificationsDenied, int? unreadCheckIntervalMinutes, int? lastOnlineStatus}) {
    return Settings(
      notificationsDenied: this.notificationsDenied.passThrough(notificationsDenied),
      unreadCheckIntervalMinutes: this.unreadCheckIntervalMinutes.passThrough(unreadCheckIntervalMinutes),
      lastOnlineStatus: this.lastOnlineStatus.passThrough(lastOnlineStatus),
    );
  }


}