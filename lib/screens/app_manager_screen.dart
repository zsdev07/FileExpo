import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import '../services/app_service.dart';

class AppManagerScreen extends StatefulWidget {
  const AppManagerScreen({super.key});

  @override
  State<AppManagerScreen> createState() => _AppManagerScreenState();
}

class _AppManagerScreenState extends State<AppManagerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AppService>().loadApps());
  }

  @override
  Widget build(BuildContext context) {
    final appService = context.watch<AppService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => appService.loadApps(),
          ),
        ],
      ),
      body: appService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: appService.apps.length,
              itemBuilder: (context, index) {
                final app = appService.apps[index];
                return ListTile(
                  leading: const Icon(Icons.android),
                  title: Text(app.name),
                  subtitle: Text('${app.packageName} (${app.versionName})'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'backup', child: Text('Backup APK')),
                      const PopupMenuItem(value: 'uninstall', child: Text('Uninstall')),
                    ],
                    onSelected: (value) {
                      if (value == 'backup') {
                        appService.backupApp(app);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Backup saved to FileExpo/Backups')),
                        );
                      } else if (value == 'uninstall') {
                        appService.uninstallApp(app.packageName);
                      }
                    },
                  ),
                  onTap: () => InstalledApps.startApp(app.packageName),
                );
              },
            ),
    );
  }
}
