import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primaryGreenStart = Color(0xFF4ADE80);
  static const Color primaryGreenEnd = Color(0xFF036027);
  static const Color primaryGreen = Color(0xFF01732C);

  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFFF5F5F5);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  static const Color error = Color(0xFFE53935);
  static const Color white = Color(0xFFFFFFFF);

  static const Color cardDark = Color(0xFF1E2035);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);

  static const Color badgeNew = Color(0xFFE53935);
  static const Color badgeRecent = Color(0xFF01732C);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreenStart, primaryGreenEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xCC1A1A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGreenOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xCC036027)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
