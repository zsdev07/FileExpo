import 'dart:io';
import 'package:flutter/services.dart';

/// Backs Settings > Advanced & Integration > "Default file manager".
/// Android has no single system role for this (unlike default browser/
/// launcher), so there's no one toggle — the real equivalent is FileExpo
/// actually working correctly when picked from the system's "Open with"
/// or "Share" chooser, which is what this resolves.
class LaunchIntentService {
  static const _channel = MethodChannel('zx.offical.fexpo/storage');

  /// The real filesystem path FileExpo was launched/shared to open, or
  /// null if it was opened normally (from its own launcher icon).
  Future<String?> getLaunchPath() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('getLaunchIntentPath');
    } on PlatformException {
      return null;
    }
  }

  /// Opens this app's system "App info" settings screen — where Android
  /// itself lets the user manage "Open by default" for whatever file
  /// types they've previously chosen FileExpo for.
  Future<void> openAppInfoSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openAppInfoSettings');
    } on PlatformException {
      // No-op.
    }
  }
}
