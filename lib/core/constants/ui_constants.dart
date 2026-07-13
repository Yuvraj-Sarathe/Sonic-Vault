import 'package:flutter/material.dart';

class UiConstants {
  // Layout
  static const double minWindowWidth = 800;
  static const double minWindowHeight = 600;
  static const double sidebarWidth = 240;
  static const double miniPlayerHeight = 64;

  // Grid
  static const double albumGridMinWidth = 160;
  static const double albumGridMaxWidth = 220;
  static const double albumGridCrossAxisCount = 4;

  // Spacing
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  // Border radius
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;

  // Animation
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);

  // Curves
  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveEmphasized = Curves.easeInOutCubicEmphasized;

  // Typography sizes
  static const double textXs = 10;
  static const double textSm = 12;
  static const double textMd = 14;
  static const double textLg = 16;
  static const double textXl = 20;
  static const double textDisplay = 24;
  static const double textHero = 32;

  // Skeleton shimmer
  static const double shimmerBaseOpacity = 0.3;
  static const double shimmerHighlightOpacity = 0.1;
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
}
