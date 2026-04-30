import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:path/path.dart' as p;

class AppService extends ChangeNotifier {
  List<AppInfo> _apps = [];
  bool _isLoading = false;

  List<AppInfo> get apps => _apps;
  bool get isLoading => _isLoading;

  Future<void> loadApps() async {
    _isLoading = true;
    notifyListeners();

    // positional args: excludeSystemApps, withIcon
    _apps = await InstalledApps.getInstalledApps(false, false);
    _apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> backupApp(AppInfo app) async {
    try {
      final result = await Process.run('pm', ['path', app.packageName]);
      final apkPath = (result.stdout as String).trim().replaceFirst('package:', '');
      if (apkPath.isEmpty) return;

      final apkFile = File(apkPath);
      final backupDir = Directory('/storage/emulated/0/FileExpo/Backups');
      if (!await backupDir.exists()) await backupDir.create(recursive: true);

      final backupPath = p.join(backupDir.path, '${app.name}_${app.versionName}.apk');
      await apkFile.copy(backupPath);
    } catch (e) {
      debugPrint('Error backing up app: $e');
    }
  }

  Future<void> uninstallApp(String packageName) async {
    await Process.run('am', ['start', '-a', 'android.intent.action.DELETE',
        '-d', 'package:$packageName']);
  }
}
