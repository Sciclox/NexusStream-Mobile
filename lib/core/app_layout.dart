import 'package:flutter/material.dart';
import 'device_profile.dart';

class AppLayout {
  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (DeviceProfile.isTv) {
      if (width > 1800) return 6;
      if (width > 1200) return 5;
      return 4;
    }
    if (DeviceProfile.isDesktop) {
      if (width > 1600) return 6;
      if (width > 1100) return 4;
      if (width > 800) return 3;
      return 2;
    }
    // Mobile
    final orientation = MediaQuery.of(context).orientation;
    if (orientation == Orientation.landscape) {
      return 4;
    }
    if (width > 600) return 3;
    return 2;
  }

  static double getCardAspectRatio(BuildContext context) {
    if (DeviceProfile.isTv) return 1.35;
    return 1.25;
  }

  static EdgeInsets getContentPadding(BuildContext context) {
    if (DeviceProfile.isTv) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    }
    if (DeviceProfile.isDesktop) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }
}
