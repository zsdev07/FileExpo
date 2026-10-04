import 'package:flutter/material.dart';
import '../services/apk_scan_service.dart';
import '../services/app_manager_service.dart';
import '../services/file_operations_service.dart';
import '../services/storage_access_service.dart';
import '../utils/file_size_formatter.dart';

class ApkInstallerScreen extends StatefulWidget {
  const ApkInstallerScreen({super.key});

  @override
  State<ApkInstallerScreen> createState() => _ApkInstallerScreenState();
}

class _ApkInstallerScreenState extends State<ApkInstallerScreen> {
  final _scanService = ApkScanService();
  final _appManager = AppManagerService();
  final _fileOps = FileOperationsService();
  final _storageService = StorageAccessService();

  bool _loading = true;
  String? _error;
  List<ApkFileEntry> _files = [];

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final root = await _storageService.getRootPath();
      final files = await _scanService.scan(root);
      if (!mounted) return;
      setState(() {
        _files = files;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't scan for APKs: $e";
        _loading = false;
      });
    }
  }

  Future<void> _install(ApkFileEntry entry) async {
    if (entry.type == ApkFileType.xapk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "XAPK install isn't supported yet — it needs extracting and a "
            'split-APK install, which is coming in a later drop.',
          ),
        ),
      );
      return;
    }
    final error = await _appManager.installApk(entry.path);
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Couldn't open installer: $error")),
    );
  }

  Future<void> _delete(ApkFileEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${entry.name}?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _fileOps.delete(entry.path);
      if (!mounted) return;
      setState(() => _files.removeWhere((f) => f.path == entry.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't delete: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APK Installer'),
        actions: [
          IconButton(
            tooltip: 'Rescan',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _scan,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Scanning storage for APK/XAPK files…'),
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
    if (_files.isEmpty) {
      return const Center(child: Text('No APK or XAPK files found'));
    }

    return RefreshIndicator(
      onRefresh: _scan,
      child: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final entry = _files[index];
          final isXapk = entry.type == ApkFileType.xapk;
          return ListTile(
            leading: Icon(
              isXapk ? Icons.archive_outlined : Icons.android_rounded,
              color: isXapk ? Colors.orange : Colors.green,
            ),
            title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${FileSizeFormatter.format(entry.size)} • ${entry.path}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: isXapk ? 'Install (not yet supported)' : 'Install',
                  icon: const Icon(Icons.install_mobile_outlined),
                  onPressed: () => _install(entry),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _delete(entry),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
