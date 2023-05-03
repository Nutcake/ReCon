class SettingsEntry<T> {
  final T? value;
  final T deflt;

  const SettingsEntry({this.value, required this.deflt});

  factory SettingsEntry.fromMap(Map map) {
    return SettingsEntry<T>(
      value: map["value"] as T,
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

  const Settings({
    this.notificationsDenied = const SettingsEntry(deflt: false),
    this.unreadCheckIntervalMinutes = const SettingsEntry(deflt: 60),
  });

  factory Settings.fromMap(Map map) {
    return Settings(
      notificationsDenied: SettingsEntry.fromMap(map["notificationsDenied"]),
      unreadCheckIntervalMinutes: SettingsEntry.fromMap(map["unreadCheckIntervalMinutes"]),
    );
  }

  Map toMap() {
    return {
      "notificationsDenied": notificationsDenied.toMap(),
      "unreadCheckIntervalMinutes": unreadCheckIntervalMinutes.toMap(),
    };
  }

  Settings copy() => copyWith();

  Settings copyWith({bool? notificationsDenied, int? unreadCheckIntervalMinutes}) {
    return Settings(
      notificationsDenied: this.notificationsDenied.passThrough(notificationsDenied),
      unreadCheckIntervalMinutes: this.unreadCheckIntervalMinutes.passThrough(unreadCheckIntervalMinutes),
    );
  }


}