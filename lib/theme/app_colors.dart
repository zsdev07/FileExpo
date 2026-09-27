import 'package:flutter/material.dart';

/// Brand colors for FileExpo.
///
/// The app defaults to a Purple + Black identity, but every screen is built
/// on top of Material 3 [ColorScheme]s, so when Material You dynamic color
/// is available (Android 12+), the whole palette below is swapped out for
/// one generated from the user's wallpaper. See [AppTheme].
class AppColors {
  AppColors._();

  /// Seed used to generate the fallback (non-dynamic) color scheme.
  static const Color seed = Color(0xFF7C4DFF); // vivid purple

  /// Pure near-black background used for the dark theme surfaces, matching
  /// the reference screenshots (true black, not just a dark grey).
  static const Color black = Color(0xFF0B0B0F);
  static const Color blackElevated = Color(0xFF141318);

  /// Accent colors used for folder/file-type icon backgrounds in file list
  /// rows (Photos, Videos, Documents, Downloads, Archives, ...).
  static const Color folderBlue = Color(0xFF1565C0);
  static const Color folderTeal = Color(0xFF00695C);
  static const Color archiveBrown = Color(0xFF6D4C41);
  static const Color apkGreen = Color(0xFF2E7D32);
  static const Color docBlue = Color(0xFF1976D2);
  static const Color danger = Color(0xFFD32F2F);
}
