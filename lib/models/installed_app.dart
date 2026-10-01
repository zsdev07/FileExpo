import 'dart:typed_data';

class InstalledApp {
  final String packageName;
  final String appName;
  final bool isSystemApp;
  final int appBytes;
  final int dataBytes;
  final int cacheBytes;
  final Uint8List icon;

  /// Null means Android has no usage record for this app (common for
  /// background-only services with no launcher activity).
  final DateTime? lastUsed;

  const InstalledApp({
    required this.packageName,
    required this.appName,
    required this.isSystemApp,
    required this.appBytes,
    required this.dataBytes,
    required this.cacheBytes,
    required this.icon,
    this.lastUsed,
  });

  int get totalBytes => appBytes + dataBytes + cacheBytes;
}
