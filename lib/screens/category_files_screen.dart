import 'dart:io';
import 'package:flutter/material.dart';
import '../models/storage_entry.dart';
import '../services/file_operations_service.dart';
import '../services/storage_scan_service.dart';
import '../utils/file_kind.dart';
import '../utils/file_size_formatter.dart';
import '../utils/storage_category.dart';
import 'viewers/audio_viewer_screen.dart';
import 'viewers/image_viewer_screen.dart';
import 'viewers/text_viewer_screen.dart';
import 'viewers/video_viewer_screen.dart';
import 'viewers/zip_preview_screen.dart';

/// Lists every file in one storage category, biggest first, with
/// multi-select delete. Pops with `true` if anything was actually deleted
/// so the Storage Analyzer knows to rescan.
class CategoryFilesScreen extends StatefulWidget {
  final StorageCategoryKind kind;
  final String label;
  final List<LargeFileEntry> files;

  const CategoryFilesScreen({
    super.key,
    required this.kind,
    required this.label,
    required this.files,
  });

  @override
  State<CategoryFilesScreen> createState() => _CategoryFilesScreenState();
}

class _CategoryFilesScreenState extends State<CategoryFilesScreen> {
  final _fileOps = FileOperationsService();
  late List<LargeFileEntry> _files;
  final Set<String> _selected = {};
  bool _changed = false;

  bool get _isImagesCategory => widget.kind == StorageCategoryKind.images;

  @override
  void initState() {
    super.initState();
    _files = [...widget.files]..sort((a, b) => b.size.compareTo(a.size));
  }

  int get _selectedBytes => _files
      .where((f) => _selected.contains(f.path))
      .fold<int>(0, (sum, f) => sum + f.size);

  void _toggle(LargeFileEntry file) {
    setState(() {
      if (_selected.contains(file.path)) {
        _selected.remove(file.path);
      } else {
        _selected.add(file.path);
      }
    });
  }

  void _selectAll() => setState(() => _selected.addAll(_files.map((f) => f.path)));

  void _clearSelection() => setState(() => _selected.clear());

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final targets = _files.where((f) => _selected.contains(f.path)).toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete ${targets.length} file${targets.length == 1 ? '' : 's'}?',
        ),
        content: Text(
          'This frees up ${FileSizeFormatter.format(_selectedBytes)} and '
          "can't be undone.",
        ),
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
    final succeeded = <String>{};
    for (final file in targets) {
      try {
        await _fileOps.delete(file.path);
        succeeded.add(file.path);
      } catch (_) {
        // left in the list; reported below
      }
    }

    setState(() {
      _files.removeWhere((f) => succeeded.contains(f.path));
      _selected.removeAll(succeeded);
      if (succeeded.isNotEmpty) _changed = true;
    });

    messenger.showSnackBar(SnackBar(
      content: Text(
        succeeded.length < targets.length
            ? "Deleted ${succeeded.length} of ${targets.length} — some files couldn't be removed."
            : 'Deleted ${succeeded.length} file${succeeded.length == 1 ? '' : 's'}',
      ),
    ));
  }

  void _openFile(LargeFileEntry file) {
    switch (FileKindResolver.resolve(file.name)) {
      case FileKind.image:
        final images = _files
            .where((f) => FileKindResolver.resolve(f.name) == FileKind.image)
            .toList();
        final entries = images
            .map((f) => StorageEntry(
                  name: f.name,
                  type: StorageEntryType.file,
                  path: f.path,
                  subtitle: FileSizeFormatter.format(f.size),
                  modified: f.modified,
                  icon: Icons.image_rounded,
                  iconBackground: Colors.pink,
                ))
            .toList();
        final index = images.indexWhere((f) => f.path == file.path);
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ImageViewerScreen(
            images: entries,
            initialIndex: index < 0 ? 0 : index,
          ),
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

  /// Photo-picker-style grid: real thumbnails, a selection circle on every
  /// cell (not gated behind a separate "selection mode"), tap to toggle,
  /// long-press to open the full-screen swipe viewer.
  Widget _buildImageGrid(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        final isSelected = _selected.contains(file.path);

        return GestureDetector(
          onTap: () => _toggle(file),
          onLongPress: () => _openFile(file),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // A small cacheWidth here is what keeps a 1000+ photo grid
              // scrolling smoothly — decoding every thumbnail at full
              // camera resolution is the same mistake that made the
              // full-screen viewer slow, just multiplied by a grid's
              // worth of images at once.
              Image.file(
                File(file.path),
                fit: BoxFit.cover,
                cacheWidth: 200,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade800,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                  ),
                ),
              ),
              if (isSelected) Container(color: Colors.black.withValues(alpha: 0.35)),
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? scheme.primary : Colors.black.withValues(alpha: 0.4),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selecting = _selected.isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label),
              Text(
                '${_files.length} file${_files.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: selecting
              ? [
                  IconButton(
                    tooltip: 'Select all',
                    icon: const Icon(Icons.select_all_rounded),
                    onPressed: _selectAll,
                  ),
                  IconButton(
                    tooltip: 'Clear selection',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _clearSelection,
                  ),
                ]
              : null,
        ),
        body: _files.isEmpty
            ? const Center(child: Text('Nothing here'))
            : _isImagesCategory
                ? _buildImageGrid(context)
                : ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: _files.length,
                itemBuilder: (context, index) {
                  final file = _files[index];
                  final isSelected = _selected.contains(file.path);
                  final previewable =
                      FileKindResolver.resolve(file.name) != FileKind.other;

                  return ListTile(
                    onTap: () => _toggle(file),
                    selected: isSelected,
                    selectedTileColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.25),
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggle(file),
                    ),
                    title: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      file.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(FileSizeFormatter.format(file.size)),
                        if (previewable)
                          IconButton(
                            tooltip: 'Preview',
                            icon: const Icon(Icons.visibility_outlined),
                            onPressed: () => _openFile(file),
                          ),
                      ],
                    ),
                  );
                },
              ),
        bottomNavigationBar: selecting
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _deleteSelected,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(
                      'Delete ${_selected.length} (${FileSizeFormatter.format(_selectedBytes)})',
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
