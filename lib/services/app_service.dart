import 'dart:io';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class AppService extends ChangeNotifier {
  List<AppInfo> _apps = [];
  bool _isLoading = false;

  List<AppInfo> get apps => _apps;
  bool get isLoading => _isLoading;

  Future<void> loadApps() async {
    _isLoading = true;
    notifyListeners();

    _apps = await FlutterDeviceApps.listApps(
      includeSystem: true,
      onlyLaunchable: true,
      includeIcons: true,
    );
    _apps.sort((a, b) =>
        (a.appName ?? '').toLowerCase().compareTo((b.appName ?? '').toLowerCase()));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> backupApp(AppInfo app) async {
    try {
      if (app.apkPath == null) return;
      final apkFile = File(app.apkPath!);
      final backupDir = Directory('/storage/emulated/0/FileExpo/Backups');
      if (!await backupDir.exists()) await backupDir.create(recursive: true);

      final backupPath = p.join(backupDir.path, '${app.appName}_${app.versionName}.apk');
      await apkFile.copy(backupPath);
    } catch (e) {
      debugPrint('Error backing up app: $e');
    }
  }

  void uninstallApp(String packageName) {
    FlutterDeviceApps.uninstallApp(packageName);
  }
}
