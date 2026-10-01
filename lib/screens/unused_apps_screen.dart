import 'package:flutter/material.dart';
import '../models/installed_app.dart';
import '../services/app_manager_service.dart';
import '../utils/file_size_formatter.dart';
import '../widgets/usage_access_gate.dart';

enum _UnusedThreshold { days30, days60, days90 }

class UnusedAppsScreen extends StatefulWidget {
  const UnusedAppsScreen({super.key});

  @override
  State<UnusedAppsScreen> createState() => _UnusedAppsScreenState();
}

class _UnusedAppsScreenState extends State<UnusedAppsScreen>
    with WidgetsBindingObserver {
  final _service = AppManagerService();

  bool? _hasAccess; // null while the first check is in flight
  bool _loading = false;
  String? _error;
  List<InstalledApp> _apps = [];
  _UnusedThreshold _threshold = _UnusedThreshold.days30;

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
      if (!mounted) return;
      setState(() {
        // System apps are rarely what someone wants to uninstall here, and
        // mostly clutter this particular list.
        _apps = apps.where((a) => !a.isSystemApp).toList();
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

  int get _thresholdDays {
    switch (_threshold) {
      case _UnusedThreshold.days30:
        return 30;
      case _UnusedThreshold.days60:
        return 60;
      case _UnusedThreshold.days90:
        return 90;
    }
  }

  List<InstalledApp> get _unusedApps {
    final cutoff = DateTime.now().subtract(Duration(days: _thresholdDays));
    final result = _apps
        .where((a) => a.lastUsed == null || a.lastUsed!.isBefore(cutoff))
        .toList();
    result.sort((a, b) {
      final aTime = a.lastUsed ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastUsed ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime); // oldest / never-used first
    });
    return result;
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
  }

  String _formatLastUsed(InstalledApp app) {
    if (app.lastUsed == null) return 'Never recorded';
    final days = DateTime.now().difference(app.lastUsed!).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return '1 day ago';
    if (days < 30) return '$days days ago';
    final months = (days / 30).floor();
    if (months < 12) return '$months month${months == 1 ? '' : 's'} ago';
    final years = (days / 365).floor();
    return '$years year${years == 1 ? '' : 's'} ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unused apps'),
        actions: [
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
        title: 'Find apps you no longer use',
        message: 'FileExpo needs "Usage access" to see when you last '
            "opened each app. You'll be taken to a system settings "
            'screen — find FileExpo in the list and turn it on.',
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
              Text('Checking app usage…'),
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

    final apps = _unusedApps;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<_UnusedThreshold>(
            segments: const [
              ButtonSegment(
                value: _UnusedThreshold.days30,
                label: Text('30+ days'),
              ),
              ButtonSegment(
                value: _UnusedThreshold.days60,
                label: Text('60+ days'),
              ),
              ButtonSegment(
                value: _UnusedThreshold.days90,
                label: Text('90+ days'),
              ),
            ],
            selected: {_threshold},
            onSelectionChanged: (selection) =>
                setState(() => _threshold = selection.first),
          ),
        ),
        Expanded(
          child: apps.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No apps unused for $_thresholdDays+ days — nice and tidy.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
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
                          'Last used: ${_formatLastUsed(app)} • '
                          '${FileSizeFormatter.format(app.totalBytes)}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Uninstall',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => _confirmUninstall(app),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
