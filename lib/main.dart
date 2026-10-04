import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'screens/storage_gate.dart';
import 'services/settings_store.dart';
import 'theme/app_theme.dart';

void main() async {
  // Settings must be loaded before the first frame — otherwise the app
  // flashes the default theme for a moment before switching to whatever
  // the user actually picked, every single launch.
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsStore.instance.load();
  runApp(const FileExpoApp());
}

class FileExpoApp extends StatelessWidget {
  const FileExpoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds whenever a Settings screen changes theme mode, accent
    // color, or anything else SettingsStore holds — changes apply live,
    // no restart needed.
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        final settings = SettingsStore.instance;

        // DynamicColorBuilder hands us wallpaper-derived ColorSchemes on
        // Android 12+ (Material You). On older devices / other platforms
        // it returns null for both, and AppTheme falls back to the
        // FileExpo Purple + Black brand palette so the app never looks
        // unthemed. An explicit accent color pick in Settings overrides
        // either of those — see SettingsStore.effectiveAccentSeed.
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            return MaterialApp(
              title: 'FileExpo',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(
                lightDynamic,
                accentSeed: settings.effectiveAccentSeed,
              ),
              darkTheme: AppTheme.dark(
                darkDynamic,
                accentSeed: settings.effectiveAccentSeed,
              ),
              themeMode: settings.themeMode.toFlutterThemeMode(),
              home: const StorageGate(),
            );
          },
        );
      },
    );
  }
}
