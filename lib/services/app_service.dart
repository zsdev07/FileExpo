import 'dart:io';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class AppService extends ChangeNotifier {
  List<Application> _apps = [];
  bool _isLoading = false;

  List<Application> get apps => _apps;
  bool get isLoading => _isLoading;

  Future<void> loadApps() async {
    _isLoading = true;
    notifyListeners();

    _apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: true,
      onlyAppsWithLaunchIntent: true,
    );
    _apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> backupApp(Application app) async {
    try {
      final apkFile = File(app.apkFilePath);
      final backupDir = Directory('/storage/emulated/0/FileExpo/Backups');
      if (!await backupDir.exists()) await backupDir.create(recursive: true);
      
      final backupPath = p.join(backupDir.path, '${app.appName}_${app.versionName}.apk');
      await apkFile.copy(backupPath);
    } catch (e) {
      debugPrint('Error backing up app: $e');
    }
  }

  void uninstallApp(String packageName) {
    DeviceApps.uninstallApp(packageName);
  }
}
