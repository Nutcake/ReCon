import 'dart:convert';

import 'package:contacts_plus_plus/models/sem_ver.dart';
import 'package:contacts_plus_plus/models/users/online_status.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

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
  final SettingsEntry<String> machineId;
  final SettingsEntry<int> themeMode;

  Settings({
    SettingsEntry<bool>? notificationsDenied,
    SettingsEntry<int>? lastOnlineStatus,
    SettingsEntry<int>? themeMode,
    SettingsEntry<String>? lastDismissedVersion,
    SettingsEntry<String>? machineId
  })
      : notificationsDenied = notificationsDenied ?? const SettingsEntry<bool>(deflt: false),
        lastOnlineStatus = lastOnlineStatus ?? SettingsEntry<int>(deflt: OnlineStatus.online.index),
        themeMode = themeMode ?? SettingsEntry<int>(deflt: ThemeMode.dark.index),
        lastDismissedVersion = lastDismissedVersion ?? SettingsEntry<String>(deflt: SemVer.zero().toString()),
        machineId = machineId ?? SettingsEntry<String>(deflt: const Uuid().v4());

  factory Settings.fromMap(Map map) {
    return Settings(
      notificationsDenied: retrieveEntryOrNull<bool>(map["notificationsDenied"]),
      lastOnlineStatus: retrieveEntryOrNull<int>(map["lastOnlineStatus"]),
      themeMode: retrieveEntryOrNull<int>(map["themeMode"]),
      lastDismissedVersion: retrieveEntryOrNull<String>(map["lastDismissedVersion"]),
      machineId: retrieveEntryOrNull<String>(map["machineId"]),
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
      "themeMode": themeMode.toMap(),
      "lastDismissedVersion": lastDismissedVersion.toMap(),
      "machineId": machineId.toMap(),
    };
  }

  Settings copy() => copyWith();

  Settings copyWith({
    bool? notificationsDenied,
    int? lastOnlineStatus,
    int? themeMode,
    String? lastDismissedVersion,
    String? machineId,
  }) {
    return Settings(
      notificationsDenied: this.notificationsDenied.passThrough(notificationsDenied),
      lastOnlineStatus: this.lastOnlineStatus.passThrough(lastOnlineStatus),
      themeMode: this.themeMode.passThrough(themeMode),
      lastDismissedVersion: this.lastDismissedVersion.passThrough(lastDismissedVersion),
      machineId: this.machineId.passThrough(machineId),
    );
  }
}