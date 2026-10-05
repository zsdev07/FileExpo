import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Builds FileExpo's light/dark [ThemeData].
///
/// [dynamicLight] / [dynamicDark] are the [ColorScheme]s produced by
/// `DynamicColorBuilder` (package:dynamic_color) from the device wallpaper.
/// When they are null (Android < 12, or the plugin isn't available yet)
/// we fall back to a scheme generated from [AppColors.seed], so the app
/// always ships with its own Purple + Black identity out of the box.
///
/// [accentSeed], when non-null, is an explicit accent color chosen in
/// Settings — it overrides both the dynamic (wallpaper) scheme and the
/// brand-seed fallback, since a deliberate in-app choice should win over
/// either automatic behavior.
class AppTheme {
  AppTheme._();

  static ThemeData light(ColorScheme? dynamicLight, {Color? accentSeed}) {
    final scheme = accentSeed != null
        ? ColorScheme.fromSeed(seedColor: accentSeed, brightness: Brightness.light)
        : (dynamicLight ?? _fallbackScheme(Brightness.light)).harmonized();
    return _themeFrom(scheme);
  }

  static ThemeData dark(ColorScheme? dynamicDark, {Color? accentSeed}) {
    final scheme = accentSeed != null
        ? ColorScheme.fromSeed(seedColor: accentSeed, brightness: Brightness.dark)
        : (dynamicDark ?? _fallbackScheme(Brightness.dark)).harmonized();
    return _themeFrom(scheme, pureBlack: true);
  }

  static ColorScheme _fallbackScheme(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
  }

  static ThemeData _themeFrom(ColorScheme scheme, {bool pureBlack = false}) {
    // Push the dark scheme's background/surface down to true black so the
    // app matches the reference screenshots instead of Material's default
    // dark-grey surfaces.
    final effectiveScheme = pureBlack
        ? scheme.copyWith(
            surface: AppColors.black,
            surfaceContainerLowest: AppColors.black,
            surfaceContainerLow: AppColors.blackElevated,
            surfaceContainer: AppColors.blackElevated,
          )
        : scheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: effectiveScheme,
      scaffoldBackgroundColor: effectiveScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: effectiveScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: effectiveScheme.onSurfaceVariant,
        textColor: effectiveScheme.onSurface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: effectiveScheme.primaryContainer,
        foregroundColor: effectiveScheme.onPrimaryContainer,
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        color: effectiveScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(
          effectiveScheme.surfaceContainerHigh,
        ),
        elevation: const WidgetStatePropertyAll(0),
      ),
      dividerTheme: DividerThemeData(
        color: effectiveScheme.outlineVariant.withValues(alpha: 0.4),
      ),
    );
  }
}
