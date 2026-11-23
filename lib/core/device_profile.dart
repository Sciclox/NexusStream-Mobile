import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum DeviceType { tv, mobile, tablet, desktop }

class DeviceProfile {
  static DeviceType _deviceType = DeviceType.mobile;
  static bool _isInitialized = false;

  static DeviceType get current => _deviceType;
  static bool get isTv => _deviceType == DeviceType.tv;
  static bool get isMobile => _deviceType == DeviceType.mobile;
  static bool get isDesktop => _deviceType == DeviceType.desktop;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      _deviceType = DeviceType.desktop;
      _isInitialized = true;
      return;
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _deviceType = DeviceType.desktop;
      _isInitialized = true;
      return;
    }

    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final isTelevision = androidInfo.systemFeatures.contains('android.software.leanback') ||
            androidInfo.systemFeatures.contains('android.hardware.type.television');

        if (isTelevision) {
          _deviceType = DeviceType.tv;
        } else {
          _deviceType = DeviceType.mobile;
        }
      } catch (e) {
        _deviceType = DeviceType.mobile;
      }
    }

    _isInitialized = true;
  }

  static void evaluateSize(BuildContext context) {
    if (isTv || isDesktop) return;
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    if (shortestSide >= 600) {
      _deviceType = DeviceType.tablet;
    }
  }
}
