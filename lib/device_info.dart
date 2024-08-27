import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Information about the device running the app.
class DeviceInfo {
  static final RegExp _r39 = RegExp(r'iPhone(10,(3|6)|11,(2|4|6)|12,(3|5))');
  static final RegExp _r41 = RegExp(r'iPhone(11,8|12,1)');
  static final RegExp _r44 = RegExp(r'iPhone(13,1|14,4)');
  static final RegExp _r47 = RegExp(r'iPhone(13,(2|3)|14,(2|5|7))');
  static final RegExp _r53 = RegExp(r'iPhone(13,4|14,(3|8))');
  static final RegExp _r55 = RegExp(r'iPhone(15,(2|3|4|5)|16,(1|2))');

  static final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  static BaseDeviceInfo? _info;
  static WindowsDeviceInfo? _windowsInfo;
  static MacOsDeviceInfo? _macOsInfo;
  static LinuxDeviceInfo? _linuxInfo;
  static IosDeviceInfo? _iosInfo;
  static AndroidDeviceInfo? _androidInfo;
  static Radius? _bezelRadius;

  /// The device information for the device running the app.
  static BaseDeviceInfo? get info => _info;

  /// The device information for Windows devices.
  ///
  /// This will be `null` if the app is not running on a Windows device.
  static WindowsDeviceInfo? get windowsInfo => _windowsInfo;

  /// The device information for macOS devices.
  ///
  /// This will be `null` if the app is not running on a macOS device.
  static MacOsDeviceInfo? get macOsInfo => _macOsInfo;

  /// The device information for Linux devices.
  ///
  /// This will be `null` if the app is not running on a Linux device.
  static LinuxDeviceInfo? get linuxInfo => _linuxInfo;

  /// The device information for iOS devices.
  ///
  /// This will be `null` if the app is not running on an iOS device.
  static IosDeviceInfo? get iosInfo => _iosInfo;

  /// The device information for Android devices.
  ///
  /// This will be `null` if the app is not running on an Android device.
  static AndroidDeviceInfo? get androidInfo => _androidInfo;

  /// The radius of the corners of the device's screen bezel (if applicable).
  ///
  /// This will be `null` if the app is running on a device with a rectangular screen.
  static Radius? get bezelRadius => _bezelRadius;

  /// Initializes device information. This method should be called before the app is run.
  static Future<void> initDeviceInfo() async {
    _info = await deviceInfo.iosInfo;

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        _iosInfo = await deviceInfo.iosInfo;

        try {
          final String model = _iosInfo!.utsname.machine;
          if (_r39.hasMatch(model)) _bezelRadius = const Radius.circular(39);
          if (_r41.hasMatch(model)) _bezelRadius = const Radius.circular(41);
          if (_r44.hasMatch(model)) _bezelRadius = const Radius.circular(44);
          if (_r47.hasMatch(model)) _bezelRadius = const Radius.circular(47);
          if (_r53.hasMatch(model)) _bezelRadius = const Radius.circular(53);
          if (_r55.hasMatch(model)) _bezelRadius = const Radius.circular(55);
        } catch (e) {
          return;
        }
        break;
      case TargetPlatform.android:
        _androidInfo = await deviceInfo.androidInfo;
        break;
      case TargetPlatform.windows:
        _windowsInfo = await deviceInfo.windowsInfo;
        break;
      case TargetPlatform.macOS:
        _macOsInfo = await deviceInfo.macOsInfo;
        break;
      case TargetPlatform.linux:
        _linuxInfo = await deviceInfo.linuxInfo;
        break;
      case TargetPlatform.fuchsia:
        break;
    }
  }
}
