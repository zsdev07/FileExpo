import 'package:flutter/material.dart';
import '../data/file_repository.dart';
import '../data/real_file_repository.dart';
import '../models/storage_entry.dart';
import '../services/clipboard_service.dart';
import '../services/file_operations_service.dart';
import '../services/storage_access_service.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/breadcrumb_bar.dart';
import '../widgets/file_context_sheet.dart';
import '../widgets/paste_bar.dart';
import '../widgets/search_top_bar.dart';
import '../widgets/storage_entry_tile.dart';

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

  void _openFolder(StorageEntry entry) {
    _exitSearch();
    setState(() => _pathStack = [..._pathStack, entry.path]);
    _load();
  }

  void _jumpToBreadcrumb(int index) {
    if (index >= _pathStack.length - 1) return;
    setState(() => _pathStack = _pathStack.sublist(0, index + 1));
    _load();
  }

  bool get _atRoot => _pathStack.length <= 1;

  void _goUp() {
    if (_atRoot) return;
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

  Future<void> _handlePaste() async {
    final clip = ClipboardService.instance.entry;
    if (clip == null) return;
    final destDir = _pathStack.last;
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (clip.isCut) {
        await _fileOps.move(clip.path, destDir);
      } else {
        await _fileOps.copy(clip.path, destDir);
      }
      ClipboardService.instance.clear();
      await _load();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Couldn't paste: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _atRoot && !_searching,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_searching) {
          _exitSearch();
        } else {
          _goUp();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _buildAppBar(),
        drawer: const _AppDrawer(),
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
            ListenableBuilder(
              listenable: ClipboardService.instance,
              builder: (context, _) {
                final clip = ClipboardService.instance.entry;
                if (clip == null) return const SizedBox.shrink();
                return PasteBar(
                  entry: clip,
                  onPaste: _handlePaste,
                  onCancel: ClipboardService.instance.clear,
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: create folder / new file sheet.
          },
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  /// Typed as [PreferredSizeWidget] explicitly — a `_searching ? A : B`
  /// expression inline in `Scaffold(appBar: ...)` gets inferred by Dart as
  /// their common `Widget` supertype (not the shared `PreferredSizeWidget`
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
            onTap: () {
              if (entry.isFolder) {
                _openFolder(entry);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Built-in viewers are coming in a later step'),
                  ),
                );
              }
            },
            onLongPress: () => showFileContextSheet(
              context: context,
              entry: entry,
              onChanged: _load,
            ),
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
