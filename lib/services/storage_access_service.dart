import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles everything needed to get real, device-wide read/write access:
///  - the true root path of primary external storage (via the small Kotlin
///    bridge in `MainActivity.kt` — path_provider only exposes app-private
///    directories, which isn't useful for a file manager)
///  - Android 11+ "All files access" (MANAGE_EXTERNAL_STORAGE), which is
///    what a file manager needs to browse anything outside its own
///    sandbox and outside the media collections
///  - the classic storage permission on Android 10 and below
class StorageAccessService {
  static const _channel = MethodChannel('zx.offical.fexpo/storage');

  static const _fallbackRoot = '/storage/emulated/0';

  Future<String> getRootPath() async {
    if (!Platform.isAndroid) return _fallbackRoot;
    try {
      final path = await _channel.invokeMethod<String>('getRootPath');
      return path ?? _fallbackRoot;
    } on PlatformException {
      return _fallbackRoot;
    }
  }

  /// True once the app can read/write anywhere on shared storage.
  Future<bool> hasFullAccess() async {
    if (!Platform.isAndroid) return true;

    try {
      final manageGranted =
          await _channel.invokeMethod<bool>('isManageStorageGranted') ??
              false;
      if (manageGranted) return true;
    } on PlatformException {
      // Fall through to the legacy permission check below.
    }

    // Android 10 (API 29) and below never has MANAGE_EXTERNAL_STORAGE —
    // the classic runtime permission is the real gate there.
    final legacy = await Permission.storage.status;
    return legacy.isGranted;
  }

  /// Kicks off whichever permission flow is relevant for this OS version.
  /// The all-files-access grant happens in system Settings, so the caller
  /// should re-check [hasFullAccess] when the app resumes.
  Future<void> requestFullAccess() async {
    if (!Platform.isAndroid) return;

    final legacyStatus = await Permission.storage.status;
    if (!legacyStatus.isGranted) {
      await Permission.storage.request();
    }

    try {
      await _channel.invokeMethod('openManageStorageSettings');
    } on PlatformException {
      // No-op on OS versions where the native side has nothing to open.
    }
  }

  /// Total/free space on primary external storage, for the Storage
  /// Analyzer's usage summary.
  Future<DeviceStorageStats> getDeviceStorageStats() async {
    if (!Platform.isAndroid) {
      return const DeviceStorageStats(totalBytes: 0, freeBytes: 0);
    }
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getStorageStats',
      );
      return DeviceStorageStats(
        totalBytes: (result?['total'] as int?) ?? 0,
        freeBytes: (result?['free'] as int?) ?? 0,
      );
    } on PlatformException {
      return const DeviceStorageStats(totalBytes: 0, freeBytes: 0);
    }
  }
}

class DeviceStorageStats {
  final int totalBytes;
  final int freeBytes;

  const DeviceStorageStats({
    required this.totalBytes,
    required this.freeBytes,
  });
}
