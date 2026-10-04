import 'package:flutter/material.dart';
import '../models/installed_app.dart';
import '../services/app_manager_service.dart';
import '../utils/file_size_formatter.dart';
import '../widgets/usage_access_gate.dart';
import 'apk_installer_screen.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> with WidgetsBindingObserver {
  final _service = AppManagerService();

  bool? _hasAccess; // null while the first check is in flight
  bool _loading = false;
  String? _error;
  List<InstalledApp> _apps = [];
  bool _showSystemApps = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_hasAccess == true) {
      _loadApps();
    } else {
      _checkAccess();
    }
  }

  Future<void> _checkAccess() async {
    final granted = await _service.hasUsageAccess();
    if (!mounted) return;
    setState(() => _hasAccess = granted);
    if (granted) _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apps = await _service.listInstalledApps();
      apps.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
      if (!mounted) return;
      setState(() {
        _apps = apps;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't list apps: $e";
        _loading = false;
      });
    }
  }

  Future<void> _confirmUninstall(InstalledApp app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Uninstall ${app.appName}?'),
        content: const Text(
          'This opens the system uninstall confirmation — FileExpo '
          "can't remove apps directly.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.uninstall(app.packageName);
    // The actual removal happens in the system dialog; the list refreshes
    // automatically via didChangeAppLifecycleState when we come back.
  }

  List<InstalledApp> get _visibleApps =>
      _showSystemApps ? _apps : _apps.where((a) => !a.isSystemApp).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apps'),
        actions: [
          IconButton(
            tooltip: 'APK Installer',
            icon: const Icon(Icons.install_mobile_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const ApkInstallerScreen(),
            )),
          ),
          if (_hasAccess == true)
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loading ? null : _loadApps,
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_hasAccess == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasAccess == false) {
      return UsageAccessGate(
        title: 'See app storage & uninstall',
        message: 'FileExpo needs "Usage access" to show how much space '
            "each app and its data take up. You'll be taken to a system "
            'settings screen — find FileExpo in the list and turn it on.',
        onGrantAccess: _service.requestUsageAccess,
      );
    }
    if (_loading && _apps.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading installed apps…'),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    final apps = _visibleApps;
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Show system apps'),
          value: _showSystemApps,
          onChanged: (value) => setState(() => _showSystemApps = value),
        ),
        Expanded(
          child: apps.isEmpty
              ? const Center(child: Text('No apps to show'))
              : RefreshIndicator(
                  onRefresh: _loadApps,
                  child: ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return ListTile(
                        leading: app.icon.isEmpty
                            ? const Icon(Icons.android_rounded)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  app.icon,
                                  width: 40,
                                  height: 40,
                                  gaplessPlayback: true,
                                ),
                              ),
                        title: Text(
                          app.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'App ${FileSizeFormatter.format(app.appBytes)} • '
                          'Data ${FileSizeFormatter.format(app.dataBytes)}',
                        ),
                        trailing: Text(FileSizeFormatter.format(app.totalBytes)),
                        onTap: app.isSystemApp ? null : () => _confirmUninstall(app),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
