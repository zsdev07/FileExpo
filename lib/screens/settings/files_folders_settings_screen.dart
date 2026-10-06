import 'package:flutter/material.dart';
import '../../services/settings_store.dart';
import '../../services/storage_access_service.dart';

class FilesFoldersSettingsScreen extends StatefulWidget {
  const FilesFoldersSettingsScreen({super.key});

  @override
  State<FilesFoldersSettingsScreen> createState() =>
      _FilesFoldersSettingsScreenState();
}

class _FilesFoldersSettingsScreenState
    extends State<FilesFoldersSettingsScreen> {
  final _storageService = StorageAccessService();
  String? _root;

  @override
  void initState() {
    super.initState();
    _storageService.getRootPath().then((path) {
      if (mounted) setState(() => _root = path);
    });
  }

  Future<void> _pickLaunchPath(SettingsStore store) async {
    final root = _root;
    if (root == null) return;

    // '' is a sentinel for "Internal Storage (default)" — distinct from
    // the dialog being dismissed, which also returns null from showDialog.
    final options = <(String, String)>[
      ('Internal Storage (default)', ''),
      ('Download', '$root/Download'),
      ('DCIM', '$root/DCIM'),
      ('Documents', '$root/Documents'),
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Default launch path'),
        children: [
          for (final option in options)
            RadioListTile<String>(
              title: Text(option.$1),
              value: option.$2,
              groupValue: store.defaultLaunchPath ?? '',
              onChanged: (value) => Navigator.pop(dialogContext, value),
            ),
        ],
      ),
    );
    if (selected == null) return;
    await store.setDefaultLaunchPath(selected.isEmpty ? null : selected);
  }

  String _launchPathLabel(String? path, String? root) {
    if (path == null) return 'Internal Storage (default)';
    if (root != null && path.startsWith(root)) {
      final relative = path.substring(root.length).replaceFirst('/', '');
      if (relative.isNotEmpty) return relative;
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        final store = SettingsStore.instance;
        return Scaffold(
          appBar: AppBar(title: const Text('Files & Folders')),
          body: ListView(
            children: [
              SwitchListTile(
                title: const Text('Show hidden items'),
                subtitle: const Text(
                  'Show files and folders whose name starts with a dot — '
                  "off by default, matching most file managers",
                ),
                value: store.showHiddenItems,
                onChanged: (value) => store.setShowHiddenItems(value),
              ),
              const Divider(height: 32),
              SwitchListTile(
                title: const Text('Hide file extensions'),
                subtitle: const Text(
                  'Show "photo" instead of "photo.jpg" in the file browser',
                ),
                value: store.hideFileExtensions,
                onChanged: (value) => store.setHideFileExtensions(value),
              ),
              const Divider(height: 32),
              SwitchListTile(
                title: const Text('Show folder sizes'),
                subtitle: const Text(
                  'Calculate and show full folder sizes inline instead of '
                  'just an item count. Each size is computed as you '
                  'scroll, so this can feel slower in folders with a lot '
                  'of large subfolders.',
                ),
                value: store.showFolderSizes,
                onChanged: (value) => store.setShowFolderSizes(value),
              ),
              const Divider(height: 32),
              ListTile(
                title: const Text('Default launch path'),
                subtitle: Text(_launchPathLabel(store.defaultLaunchPath, _root)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _root == null ? null : () => _pickLaunchPath(store),
              ),
            ],
          ),
        );
      },
    );
  }
}
