
class Settings {
  static const Settings _defaultSettings = Settings(notificationsDenied: true, unreadCheckIntervalMinutes: 0);
  final bool notificationsDenied;
  final int unreadCheckIntervalMinutes;

  const Settings({required this.notificationsDenied, required this.unreadCheckIntervalMinutes});

  factory Settings.def() => _defaultSettings;

  factory Settings.fromMap(Map map) {
    return Settings(
      notificationsDenied: map["notificationsDenied"] ?? _defaultSettings.notificationsDenied,
      unreadCheckIntervalMinutes: map["unreadCheckIntervalMinutes"] ?? _defaultSettings.unreadCheckIntervalMinutes,
    );
  }

  Map toMap() {
    return {
      "notificationsDenied": notificationsDenied,
      "unreadCheckIntervalMinutes": unreadCheckIntervalMinutes,
    };
  }

  Settings copy() => copyWith();

  Settings copyWith({bool? notificationsDenied, int? unreadCheckIntervalMinutes}) {
    return Settings(
      notificationsDenied: notificationsDenied ?? this.notificationsDenied,
      unreadCheckIntervalMinutes: unreadCheckIntervalMinutes ?? this.unreadCheckIntervalMinutes,
    );
  }
}