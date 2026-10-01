import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../data/file_repository.dart';
import '../data/real_file_repository.dart';
import '../models/storage_entry.dart';
import '../services/archive_service.dart';
import '../services/clipboard_service.dart';
import '../services/file_operations_service.dart';
import '../services/storage_access_service.dart';
import '../utils/file_kind.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/breadcrumb_bar.dart';
import '../widgets/clipboard_status_bar.dart';
import '../widgets/paste_bar.dart';
import '../widgets/search_top_bar.dart';
import '../widgets/selection_action_bar.dart';
import '../widgets/selection_top_bar.dart';
import '../widgets/storage_entry_tile.dart';
import 'apps_screen.dart';
import 'storage_analyzer_screen.dart';
import 'viewers/audio_viewer_screen.dart';
import 'viewers/image_viewer_screen.dart';
import 'viewers/text_viewer_screen.dart';
import 'viewers/video_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FileRepository _repository = RealFileRepository();
  final _storageService = StorageAccessService();
  final _fileOps = FileOperationsService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();

  /// Every directory from the storage root down to the current one, so
  /// breadcrumb taps can jump straight back to any ancestor.
  List<String> _pathStack = [];
  List<StorageEntry> _entries = [];
  bool _loading = true;
  String? _error;

  bool _searching = false;
  String _query = '';

  Set<String> _selectedPaths = {};
  bool get _selecting => _selectedPaths.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final root = await _storageService.getRootPath();
    _pathStack = [root];
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await _repository.list(_pathStack.last);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't read this folder — it may be restricted.";
        _entries = [];
        _loading = false;
      });
    }
  }

  // --- Navigation ------------------------------------------------------

  void _openFolder(StorageEntry entry) {
    _exitSearch();
    _clearSelection();
    setState(() => _pathStack = [..._pathStack, entry.path]);
    _load();
  }

  void _jumpToBreadcrumb(int index) {
    if (index >= _pathStack.length - 1) return;
    _clearSelection();
    setState(() => _pathStack = _pathStack.sublist(0, index + 1));
    _load();
  }

  bool get _atRoot => _pathStack.length <= 1;

  void _goUp() {
    if (_atRoot) return;
    _clearSelection();
    setState(() => _pathStack = _pathStack.sublist(0, _pathStack.length - 1));
    _load();
  }

  List<String> get _breadcrumbSegments {
    if (_pathStack.isEmpty) return const ['Internal storage'];
    return [
      'Internal storage',
      for (final full in _pathStack.skip(1))
        full.split('/').where((s) => s.isNotEmpty).last,
    ];
  }

  // --- Search ------------------------------------------------------

  List<StorageEntry> get _visibleEntries {
    if (!_searching || _query.trim().isEmpty) return _entries;
    final q = _query.toLowerCase();
    return _entries.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  void _enterSearch() => setState(() => _searching = true);

  void _exitSearch() {
    if (!_searching) return;
    setState(() {
      _searching = false;
      _query = '';
      _searchController.clear();
    });
  }

  // --- Selection ------------------------------------------------------

  List<StorageEntry> get _selectedEntries =>
      _entries.where((e) => _selectedPaths.contains(e.path)).toList();

  void _toggleSelect(StorageEntry entry) {
    setState(() {
      if (_selectedPaths.contains(entry.path)) {
        _selectedPaths.remove(entry.path);
      } else {
        _selectedPaths.add(entry.path);
      }
    });
  }

  void _clearSelection() {
    if (_selectedPaths.isEmpty) return;
    setState(() => _selectedPaths = {});
  }

  void _selectAll() {
    setState(() => _selectedPaths = _visibleEntries.map((e) => e.path).toSet());
  }

  void _invertSelection() {
    setState(() {
      final inverted = <String>{};
      for (final e in _visibleEntries) {
        if (!_selectedPaths.contains(e.path)) inverted.add(e.path);
      }
      _selectedPaths = inverted;
    });
  }

  void _cutSelection() {
    ClipboardService.instance.setEntries(_selectedEntries, isCut: true);
    _clearSelection();
  }

  void _copySelection() {
    ClipboardService.instance.setEntries(_selectedEntries, isCut: false);
    _clearSelection();
  }

  Future<void> _deleteSelection() async {
    final targets = _selectedEntries;
    if (targets.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete ${targets.length} item${targets.length == 1 ? '' : 's'}?',
        ),
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

    final messenger = ScaffoldMessenger.of(context);
    try {
      for (final e in targets) {
        await _fileOps.delete(e.path);
      }
      _clearSelection();
      await _load();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Couldn't delete everything: $e")),
      );
      await _load();
    }
  }

  Future<void> _shareSelection() async {
    final targets = _selectedEntries;
    if (targets.isEmpty) return;
    if (targets.any((e) => e.isFolder)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Folders can't be shared directly — zip them first."),
        ),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(files: targets.map((e) => XFile(e.path)).toList()),
    );
  }

  Future<void> _renameSelection() async {
    if (_selectedEntries.length != 1) return;
    final entry = _selectedEntries.first;
    final controller = TextEditingController(text: entry.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == entry.name) return;

    try {
      await _fileOps.rename(entry.path, newName);
      _clearSelection();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't rename: $e")));
    }
  }

  void _showInfo(StorageEntry entry) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(entry.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: 'Type', value: entry.isFolder ? 'Folder' : 'File'),
            _InfoRow(label: 'Location', value: entry.path),
            _InfoRow(
              label: entry.isFolder ? 'Contents' : 'Size',
              value: entry.subtitle,
            ),
            _InfoRow(label: 'Modified', value: entry.modified.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    _clearSelection();
  }

  Future<String> _uniqueZipPath(String dir, String baseZipName) async {
    var candidate = '$dir/$baseZipName';
    if (!await File(candidate).exists()) return candidate;

    final stem = baseZipName.substring(0, baseZipName.length - 4); // strip .zip
    var counter = 1;
    candidate = '$dir/$stem ($counter).zip';
    while (await File(candidate).exists()) {
      counter++;
      candidate = '$dir/$stem ($counter).zip';
    }
    return candidate;
  }

  Future<void> _compressSelection(List<StorageEntry> targets) async {
    if (targets.isEmpty) return;
    final destDir = _pathStack.last;
    final baseName =
        targets.length == 1 ? '${targets.first.name}.zip' : 'Archive.zip';
    final destPath = await _uniqueZipPath(destDir, baseName);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Compressing…')));

    try {
      await ArchiveService().compressToZip(
        sourcePaths: targets.map((e) => e.path).toList(),
        destZipPath: destPath,
      );
      _clearSelection();
      await _load();
      messenger.showSnackBar(
        SnackBar(content: Text('Created ${destPath.split('/').last}')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Couldn't compress: $e")));
    }
  }

  Future<void> _extractSingle(StorageEntry entry) async {
    final service = ArchiveService();
    final messenger = ScaffoldMessenger.of(context);
    final folderName = entry.name.substring(0, entry.name.length - 4);
    final destDir = '${_pathStack.last}/$folderName';
    messenger.showSnackBar(const SnackBar(content: Text('Extracting…')));

    try {
      await service.extractZip(zipPath: entry.path, destDir: destDir);
      _clearSelection();
      await _load();
      messenger.showSnackBar(SnackBar(content: Text('Extracted to $folderName')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Couldn't extract: $e")));
    }
  }

  Future<void> _showMoreMenu() async {
    final targets = _selectedEntries;
    if (targets.isEmpty) return;
    final single = targets.length == 1 ? targets.first : null;
    final canExtract = single != null &&
        !single.isFolder &&
        ArchiveService().canExtract(single.name);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (single != null)
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Information'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showInfo(single);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Compress…'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _compressSelection(targets);
                },
              ),
              if (canExtract)
                ListTile(
                  leading: const Icon(Icons.visibility_outlined),
                  title: const Text('Open as archive'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _extractSingle(single!);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _openFile(StorageEntry entry) {
    switch (FileKindResolver.resolve(entry.name)) {
      case FileKind.image:
        final images = _entries
            .where((e) =>
                !e.isFolder && FileKindResolver.resolve(e.name) == FileKind.image)
            .toList();
        final index = images.indexWhere((e) => e.path == entry.path);
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ImageViewerScreen(
            images: images,
            initialIndex: index < 0 ? 0 : index,
          ),
        ));
        break;
      case FileKind.video:
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => VideoViewerScreen(path: entry.path, title: entry.name),
        ));
        break;
      case FileKind.audio:
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => AudioViewerScreen(path: entry.path, title: entry.name),
        ));
        break;
      case FileKind.text:
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => TextViewerScreen(path: entry.path, title: entry.name),
        ));
        break;
      case FileKind.other:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Can't preview this file type yet — long-press it and use Share to open it elsewhere.",
            ),
          ),
        );
    }
  }

  // --- Clipboard / paste ------------------------------------------------

  Future<void> _handlePaste() async {
    final items = ClipboardService.instance.entries;
    if (items.isEmpty) return;
    final destDir = _pathStack.last;
    final messenger = ScaffoldMessenger.of(context);

    try {
      for (final item in items) {
        if (item.isCut) {
          await _fileOps.move(item.path, destDir);
        } else {
          await _fileOps.copy(item.path, destDir);
        }
      }
      ClipboardService.instance.clear();
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Couldn't paste everything: $e")));
      await _load();
    }
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    try {
      await _fileOps.createFolder(_pathStack.last, name);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't create folder: $e")));
    }
  }

  // --- Build ------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ClipboardService.instance,
      builder: (context, _) => PopScope(
        canPop: _atRoot && !_searching && !_selecting,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_searching) {
            _exitSearch();
          } else if (_selecting) {
            _clearSelection();
          } else {
            _goUp();
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          appBar: _buildAppBar(),
          drawer: _selecting ? null : const _AppDrawer(),
          body: Column(
            children: [
              if (!_searching) ...[
                BreadcrumbBar(
                  segments: _breadcrumbSegments,
                  onSegmentTap: _jumpToBreadcrumb,
                ),
                const SizedBox(height: 4),
              ],
              Expanded(child: _buildBody(context)),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(),
          floatingActionButton: _selecting
              ? null
              : FloatingActionButton(
                  onPressed: _createFolder,
                  child: const Icon(Icons.add_rounded),
                ),
        ),
      ),
    );
  }

  /// Typed as [PreferredSizeWidget] explicitly — an inline `cond ? A : B`
  /// in `Scaffold(appBar: ...)` gets inferred by Dart as the branches'
  /// common `Widget` supertype (not the shared `PreferredSizeWidget`
  /// interface), which `Scaffold.appBar` then rejects. Returning it from a
  /// method with an explicit return type sidesteps that inference.
  PreferredSizeWidget _buildAppBar() {
    if (_searching) {
      return SearchTopBar(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        onClose: _exitSearch,
      );
    }
    if (_selecting) {
      return SelectionTopBar(
        selectedCount: _selectedPaths.length,
        onClose: _clearSelection,
        onSelectAll: _selectAll,
        onInvertSelection: _invertSelection,
      );
    }
    if (!ClipboardService.instance.isEmpty) {
      return ClipboardStatusBar(
        count: ClipboardService.instance.length,
        onClear: ClipboardService.instance.clear,
      );
    }
    return AppTopBar(
      title: 'My Files',
      subtitle: _loading
          ? 'Loading…'
          : '${_entries.length} item${_entries.length == 1 ? '' : 's'}',
      onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      onSearchTap: _enterSearch,
      onMoreTap: () {},
    );
  }

  /// Lives in `Scaffold.bottomNavigationBar` (not stacked inside the body)
  /// so the FAB automatically repositions above it instead of overlapping.
  Widget? _buildBottomBar() {
    if (_selecting) {
      final entries = _selectedEntries;
      final singleSelected = entries.length == 1;
      final hasFolder = entries.any((e) => e.isFolder);
      return SelectionActionBar(
        onCut: _cutSelection,
        onCopy: _copySelection,
        onDelete: _deleteSelection,
        onShare: hasFolder ? null : _shareSelection,
        onRename: singleSelected ? _renameSelection : null,
        onMore: _showMoreMenu,
      );
    }
    if (!ClipboardService.instance.isEmpty) {
      return PasteBar(
        count: ClipboardService.instance.length,
        onPaste: _handlePaste,
        onNewFolder: _createFolder,
      );
    }
    return null;
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _MessageState(icon: Icons.lock_outline_rounded, message: _error!);
    }

    final visible = _visibleEntries;
    if (_entries.isEmpty) {
      return const _MessageState(
        icon: Icons.folder_off_rounded,
        message: 'Nothing here yet',
      );
    }
    if (_searching && visible.isEmpty) {
      return _MessageState(
        icon: Icons.search_off_rounded,
        message: 'No matches for "$_query"',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final entry = visible[index];
          return StorageEntryTile(
            entry: entry,
            selectionMode: _selecting,
            selected: _selectedPaths.contains(entry.path),
            onTap: () {
              if (_selecting) {
                _toggleSelect(entry);
                return;
              }
              if (entry.isFolder) {
                _openFolder(entry);
              } else {
                _openFile(entry);
              }
            },
            onLongPress: () => _toggleSelect(entry),
          );
        },
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _MessageState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: scheme.outline),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Minimal placeholder nav drawer (Storage analyzer / Vault / Network /
/// Apps / Settings) — filled in properly once those features are built.
class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    final destinations = <(IconData, String)>[
      (Icons.folder_rounded, 'Files'),
      (Icons.pie_chart_rounded, 'Storage analyzer'),
      (Icons.lock_rounded, 'Vault'),
      (Icons.dns_rounded, 'Network'),
      (Icons.android_rounded, 'Apps'),
      (Icons.settings_rounded, 'Settings'),
    ];
    return NavigationDrawer(
      onDestinationSelected: (index) {
        Navigator.of(context).pop(); // close the drawer
        switch (index) {
          case 0:
            break; // already on Files
          case 1:
            Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const StorageAnalyzerScreen(),
            ));
            break;
          case 4:
            Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const AppsScreen(),
            ));
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming soon')),
            );
        }
      },
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 24, 16, 16),
          child: Text('FileExpo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        for (final d in destinations)
          NavigationDrawerDestination(icon: Icon(d.$1), label: Text(d.$2)),
      ],
    );
  }
}
