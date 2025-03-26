import 'package:flutter/material.dart';

class ResponsiveUtils {
  final BuildContext context;
  final double _baseWidth = 360.0; // Base width for scaling (reference: medium-sized phone)

  ResponsiveUtils({required this.context});

  // Screen size properties
  Size get screenSize => MediaQuery.of(context).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  // Device type detection
  bool get isTablet => screenWidth > 600;
  bool get isLargePhone => screenWidth > 400 && screenWidth <= 600;
  bool get isSmallPhone => screenWidth <= 400;

  // Orientation
  bool get isLandscape => screenWidth > screenHeight;

  // Scale factor based on screen width
  double get scaleFactor => screenWidth / _baseWidth;

  // Dynamic pixel - scales based on screen size
  double dp(double size) {
    // Tablets get slightly larger elements
    double factor = isTablet ? scaleFactor * 1.1 : scaleFactor;

    // But we don't want elements to get too large on big screens
    if (factor > 1.5) factor = 1.5;

    // And we don't want elements to get too small on tiny screens
    if (factor < 0.8) factor = 0.8;

    return size * factor;
  }

  // Percentage of screen width
  double wp(double percentage) {
    return screenWidth * percentage / 100;
  }

  // Percentage of screen height
  double hp(double percentage) {
    return screenHeight * percentage / 100;
  }

  // Safe area
  EdgeInsets get safePadding => MediaQuery.of(context).padding;

  // Text scale factor to ensure readable text even if user has large system font
  double get textScaleFactor {
    double systemScale = MediaQuery.of(context).textScaleFactor;
    // Limit text scaling to reasonable bounds
    if (systemScale > 1.3) return 1.3;
    if (systemScale < 0.8) return 0.8;
    return systemScale;
  }

  // Get a responsive font size
  double fontSize(double size) {
    return dp(size) / textScaleFactor;
  }
}
