import 'package:flutter/material.dart';
import '../models/storage_entry.dart';
import '../services/storage_access_service.dart';
import '../services/storage_scan_service.dart';
import '../theme/app_colors.dart';
import '../utils/file_kind.dart';
import '../utils/file_size_formatter.dart';
import '../utils/storage_category.dart';
import 'apps_screen.dart';
import 'category_files_screen.dart';
import 'unused_apps_screen.dart';
import 'viewers/audio_viewer_screen.dart';
import 'viewers/image_viewer_screen.dart';
import 'viewers/text_viewer_screen.dart';
import 'viewers/video_viewer_screen.dart';
import 'viewers/zip_preview_screen.dart';

class StorageAnalyzerScreen extends StatefulWidget {
  const StorageAnalyzerScreen({super.key});

  @override
  State<StorageAnalyzerScreen> createState() => _StorageAnalyzerScreenState();
}

class _StorageAnalyzerScreenState extends State<StorageAnalyzerScreen> {
  final _storageService = StorageAccessService();
  final _scanService = StorageScanService();

  bool _loading = true;
  String? _error;
  int _totalBytes = 0;
  int _freeBytes = 0;
  ScanResult? _result;
  bool _expandedLargest = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final root = await _storageService.getRootPath();
      final stats = await _storageService.getDeviceStorageStats();
      final result = await _scanService.scan(root);
      if (!mounted) return;
      setState(() {
        _totalBytes = stats.totalBytes;
        _freeBytes = stats.freeBytes;
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't analyze storage: $e";
        _loading = false;
      });
    }
  }

  void _openFile(LargeFileEntry file) {
    switch (FileKindResolver.resolve(file.name)) {
      case FileKind.image:
        final entry = StorageEntry(
          name: file.name,
          type: StorageEntryType.file,
          path: file.path,
          subtitle: FileSizeFormatter.format(file.size),
          modified: file.modified,
          icon: Icons.image_rounded,
          iconBackground: Colors.pink,
        );
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ImageViewerScreen(images: [entry], initialIndex: 0),
        ));
        break;
      case FileKind.video:
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => VideoViewerScreen(path: file.path, title: file.name),
        ));
        break;
      case FileKind.audio:
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => AudioViewerScreen(path: file.path, title: file.name),
        ));
        break;
      case FileKind.text:
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => TextViewerScreen(path: file.path, title: file.name),
        ));
        break;
      case FileKind.zipArchive:
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ZipPreviewScreen(path: file.path, title: file.name),
        ));
        break;
      case FileKind.other:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Can't preview this file type yet.")),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage analyzer'),
        actions: [
          IconButton(
            tooltip: 'Rescan',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _run,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Scanning storage… this can take a moment on large devices.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final result = _result!;
    final usedBytes = _totalBytes - _freeBytes;

    return RefreshIndicator(
      onRefresh: _run,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DeviceUsageCard(
            totalBytes: _totalBytes,
            usedBytes: usedBytes,
            freeBytes: _freeBytes,
          ),
          const SizedBox(height: 24),
          Text('By category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _CategoryBar(categoryBytes: result.categoryBytes),
          const SizedBox(height: 12),
          for (final kind in StorageCategoryKind.values)
            if ((result.categoryBytes[kind] ?? 0) > 0)
              _CategoryTile(
                kind: kind,
                bytes: result.categoryBytes[kind] ?? 0,
                count: result.categoryCounts[kind] ?? 0,
                totalBytes: result.scannedBytes,
                onTap: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => CategoryFilesScreen(
                        kind: kind,
                        label: _categoryLabel(kind),
                        files: result.categoryFiles[kind] ?? const [],
                      ),
                    ),
                  );
                  if (changed == true) _run();
                },
              ),
          const SizedBox(height: 24),
          Text('More', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.folderBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.apps_outlined, color: Colors.white, size: 20),
            ),
            title: const Text('Apps'),
            subtitle: const Text('App + data size per app, uninstall'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const AppsScreen(),
            )),
          ),
          _ComingSoonTile(
            icon: Icons.delete_sweep_outlined,
            color: AppColors.danger,
            label: 'Recycle bin',
            subtitle: 'Recover recently deleted files',
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.schedule_outlined, color: Colors.white, size: 20),
            ),
            title: const Text('Unused apps'),
            subtitle: const Text("Apps you haven't opened in a while"),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const UnusedAppsScreen(),
            )),
          ),
          const SizedBox(height: 24),
          Text('Largest files', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (result.largestFiles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Nothing scanned yet.'),
            )
          else ...[
            for (final file in _expandedLargest
                ? result.largestFiles
                : result.largestFiles.take(4).toList())
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_categoryIcon(StorageCategoryResolver.resolve(file.name))),
                title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(file.path, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(FileSizeFormatter.format(file.size)),
                onTap: () => _openFile(file),
              ),
            if (result.largestFiles.length > 4)
              Center(
                child: TextButton(
                  onPressed: () =>
                      setState(() => _expandedLargest = !_expandedLargest),
                  child: Text(_expandedLargest ? 'Show less' : 'View more'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

String _categoryLabel(StorageCategoryKind kind) {
  switch (kind) {
    case StorageCategoryKind.images:
      return 'Images';
    case StorageCategoryKind.videos:
      return 'Videos';
    case StorageCategoryKind.audio:
      return 'Audio';
    case StorageCategoryKind.documents:
      return 'Documents';
    case StorageCategoryKind.archives:
      return 'Archives';
    case StorageCategoryKind.apks:
      return 'Apps (APKs)';
    case StorageCategoryKind.other:
      return 'Other';
  }
}

Color _categoryColor(StorageCategoryKind kind) {
  switch (kind) {
    case StorageCategoryKind.images:
      return Colors.pink.shade400;
    case StorageCategoryKind.videos:
      return AppColors.folderTeal;
    case StorageCategoryKind.audio:
      return Colors.orange.shade700;
    case StorageCategoryKind.documents:
      return AppColors.docBlue;
    case StorageCategoryKind.archives:
      return AppColors.archiveBrown;
    case StorageCategoryKind.apks:
      return AppColors.apkGreen;
    case StorageCategoryKind.other:
      return Colors.blueGrey;
  }
}

IconData _categoryIcon(StorageCategoryKind kind) {
  switch (kind) {
    case StorageCategoryKind.images:
      return Icons.image_rounded;
    case StorageCategoryKind.videos:
      return Icons.movie_rounded;
    case StorageCategoryKind.audio:
      return Icons.audiotrack_rounded;
    case StorageCategoryKind.documents:
      return Icons.description_rounded;
    case StorageCategoryKind.archives:
      return Icons.folder_zip_rounded;
    case StorageCategoryKind.apks:
      return Icons.android_rounded;
    case StorageCategoryKind.other:
      return Icons.insert_drive_file_rounded;
  }
}

class _DeviceUsageCard extends StatelessWidget {
  final int totalBytes;
  final int usedBytes;
  final int freeBytes;

  const _DeviceUsageCard({
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final usedFraction = totalBytes == 0 ? 0.0 : usedBytes / totalBytes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${FileSizeFormatter.format(usedBytes)} used of ${FileSizeFormatter.format(totalBytes)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${FileSizeFormatter.format(freeBytes)} free',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: usedFraction.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(scheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final Map<StorageCategoryKind, int> categoryBytes;

  const _CategoryBar({required this.categoryBytes});

  @override
  Widget build(BuildContext context) {
    final total = categoryBytes.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 16,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      );
    }

    final segments = <Widget>[];
    for (final kind in StorageCategoryKind.values) {
      final bytes = categoryBytes[kind] ?? 0;
      if (bytes <= 0) continue;
      segments.add(Expanded(
        flex: bytes,
        child: Container(color: _categoryColor(kind)),
      ));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 16,
        child: Row(children: segments),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final StorageCategoryKind kind;
  final int bytes;
  final int count;
  final int totalBytes;
  final VoidCallback? onTap;

  const _CategoryTile({
    required this.kind,
    required this.bytes,
    required this.count,
    required this.totalBytes,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percent = totalBytes == 0 ? 0.0 : (bytes / totalBytes * 100);
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _categoryColor(kind),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(_categoryIcon(kind), color: Colors.white, size: 20),
      ),
      title: Text(_categoryLabel(kind)),
      subtitle: Text('$count file${count == 1 ? '' : 's'}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(FileSizeFormatter.format(bytes)),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Honest placeholder row for a feature that isn't built yet — visibly
/// disabled rather than pretending to work. Tapping just explains that.
class _ComingSoonTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;

  const _ComingSoonTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: 0.55,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(label),
        subtitle: Text(subtitle),
        trailing: Text(
          'Soon',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming soon')),
          );
        },
      ),
    );
  }
}
