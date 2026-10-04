import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../models/installed_app.dart';

/// Bridges Android's package manager + per-app storage stats.
///
/// Listing every installed app needs the QUERY_ALL_PACKAGES manifest
/// permission (already declared); getting each app's real app/data/cache
/// size needs the user to grant "Usage access" — a special permission
/// granted through its own Settings screen, the same shape as the
/// all-files-access flow in [StorageAccessService].
class AppManagerService {
  static const _channel = MethodChannel('zx.offical.fexpo/storage');

  Future<bool> hasUsageAccess() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> requestUsageAccess() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } on PlatformException {
      // No-op on OS versions where nothing handles this intent.
    }
  }

  Future<List<InstalledApp>> listInstalledApps() async {
    if (!Platform.isAndroid) return const [];
    final raw = await _channel.invokeMethod<List<Object?>>('listInstalledApps');
    if (raw == null) return const [];

    return raw
        .whereType<Map<Object?, Object?>>()
        .map((m) => InstalledApp(
              packageName: m['packageName'] as String? ?? '',
              appName: m['appName'] as String? ?? '',
              isSystemApp: m['isSystemApp'] as bool? ?? false,
              appBytes: (m['appBytes'] as int?) ?? 0,
              dataBytes: (m['dataBytes'] as int?) ?? 0,
              cacheBytes: (m['cacheBytes'] as int?) ?? 0,
              icon: (m['icon'] as Uint8List?) ?? Uint8List(0),
              lastUsed: ((m['lastUsed'] as int?) ?? 0) > 0
                  ? DateTime.fromMillisecondsSinceEpoch(m['lastUsed'] as int)
                  : null,
            ))
        .toList();
  }

  Future<void> uninstall(String packageName) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('uninstallApp', {'packageName': packageName});
    } on PlatformException {
      // No-op.
    }
  }

  /// Fires the system's install confirmation for a .apk file. Returns null
  /// on success, or a human-readable error message on failure — the first
  /// tap on an unrecognized source shows Android's own "allow installs
  /// from this app" prompt inline, no separate gate screen needed here.
  Future<String?> installApk(String path) async {
    if (!Platform.isAndroid) return 'Only supported on Android';
    try {
      await _channel.invokeMethod('installApk', {'path': path});
      return null;
    } on PlatformException catch (e) {
      return e.message ?? 'Unknown error';
    }
  }
}
