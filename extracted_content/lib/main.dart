import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'screens/storage_gate.dart';
import 'theme/app_theme.dart';

void main() => runApp(const FileExpoApp());

class FileExpoApp extends StatelessWidget {
  const FileExpoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // DynamicColorBuilder hands us wallpaper-derived ColorSchemes on
    // Android 12+ (Material You). On older devices / other platforms it
    // returns null for both, and AppTheme falls back to the FileExpo
    // Purple + Black brand palette so the app never looks unthemed.
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: 'FileExpo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(lightDynamic),
          darkTheme: AppTheme.dark(darkDynamic),
          themeMode: ThemeMode.system,
          home: const StorageGate(),
        );
      },
    );
  }
}
