import 'dart:io';
import 'package:flutter/material.dart';
import '../services/launch_intent_service.dart';
import '../services/settings_store.dart';
import '../services/storage_access_service.dart';
import 'external_file_opener.dart';
import 'home_screen.dart';
import 'permission_gate_screen.dart';
import 'tabs_host.dart';

/// Wraps [HomeScreen] and keeps it hidden behind [PermissionGateScreen]
/// until FileExpo actually has storage access. The all-files-access grant
/// happens in system Settings, so this widget re-checks whenever the app
/// comes back to the foreground rather than only once at startup.
class StorageGate extends StatefulWidget {
  const StorageGate({super.key});

  @override
  State<StorageGate> createState() => _StorageGateState();
}

class _StorageGateState extends State<StorageGate>
    with WidgetsBindingObserver {
  final _service = StorageAccessService();

  bool? _hasAccess; // null while the first check is in flight
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final granted = await _service.hasFullAccess();
    if (!mounted) return;
    setState(() {
      _hasAccess = granted;
      _requesting = false;
    });
    if (granted) _handleLaunchIntent();
  }

  /// If FileExpo was opened from another app's "Open with" / "Share",
  /// open that file in the matching viewer. The native side hands the
  /// intent over exactly once, so calling this on every resume is safe —
  /// returning to the app later won't re-open the same file.
  Future<void> _handleLaunchIntent() async {
    final path = await LaunchIntentService().getLaunchPath();
    if (path == null || !mounted) return;
    if (!await File(path).exists()) return;
    if (!mounted) return;
    openExternalFile(context, path);
  }

  Future<void> _requestAccess() async {
    setState(() => _requesting = true);
    await _service.requestFullAccess();
    // On Android <= 10 the classic permission dialog resolves immediately,
    // so re-check right away too (the resume listener above covers the
    // Android 11+ Settings round-trip).
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasAccess == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasAccess == false) {
      return PermissionGateScreen(
        onGrantAccess: _requestAccess,
        requesting: _requesting,
      );
    }
    // Reacts live to Settings > MultiTasking & Navigation > "Enable tabs"
    // — no restart needed to switch shells.
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) => SettingsStore.instance.tabsEnabled
          ? const TabsHost()
          : const HomeScreen(),
    );
  }
}
