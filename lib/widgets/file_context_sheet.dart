import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/storage_entry.dart';
import '../services/archive_service.dart';
import '../services/clipboard_service.dart';
import '../services/file_operations_service.dart';

/// Shows the long-press bottom sheet for [entry] and wires up every action.
/// [onChanged] is called after anything that mutates the filesystem
/// (rename/delete/compress/extract) so the caller can reload its listing.
Future<void> showFileContextSheet({
  required BuildContext context,
  required StorageEntry entry,
  required VoidCallback onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                entry.name,
                style: Theme.of(sheetContext).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(entry.isFolder ? 'Folder' : 'File'),
            ),
            const Divider(height: 1),
            if (!entry.isFolder)
              _SheetAction(
                icon: Icons.visibility_outlined,
                label: 'Open as archive',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openAsArchive(context, entry, onChanged);
                },
              ),
            _SheetAction(
              icon: Icons.archive_outlined,
              label: 'Compress…',
              onTap: () {
                Navigator.pop(sheetContext);
                _compress(context, entry, onChanged);
              },
            ),
            _SheetAction(
              icon: Icons.info_outline,
              label: 'Information',
              onTap: () {
                Navigator.pop(sheetContext);
                _showInfo(context, entry);
              },
            ),
            _SheetAction(
              icon: Icons.copy_outlined,
              label: 'Copy',
              onTap: () {
                ClipboardService.instance.setCopy(entry);
                Navigator.pop(sheetContext);
              },
            ),
            _SheetAction(
              icon: Icons.cut_outlined,
              label: 'Cut',
              onTap: () {
                ClipboardService.instance.setCut(entry);
                Navigator.pop(sheetContext);
              },
            ),
            _SheetAction(
              icon: Icons.delete_outline,
              label: 'Delete',
              onTap: () {
                Navigator.pop(sheetContext);
                _delete(context, entry, onChanged);
              },
            ),
            _SheetAction(
              icon: Icons.edit_outlined,
              label: 'Rename',
              onTap: () {
                Navigator.pop(sheetContext);
                _rename(context, entry, onChanged);
              },
            ),
            if (!entry.isFolder)
              _SheetAction(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _share(entry);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}

String _parentOf(String path) {
  final idx = path.lastIndexOf('/');
  return idx <= 0 ? '/' : path.substring(0, idx);
}

void _share(StorageEntry entry) {
  SharePlus.instance.share(ShareParams(files: [XFile(entry.path)]));
}

Future<void> _delete(
  BuildContext context,
  StorageEntry entry,
  VoidCallback onChanged,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete "${entry.name}"?'),
      content: Text(
        entry.isFolder
            ? 'This folder and everything inside it will be permanently deleted.'
            : 'This file will be permanently deleted.',
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

  try {
    await FileOperationsService().delete(entry.path);
    onChanged();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Couldn't delete: $e")));
  }
}

Future<void> _rename(
  BuildContext context,
  StorageEntry entry,
  VoidCallback onChanged,
) async {
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
    await FileOperationsService().rename(entry.path, newName);
    onChanged();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Couldn't rename: $e")));
  }
}

void _showInfo(BuildContext context, StorageEntry entry) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        entry.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
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

Future<void> _compress(
  BuildContext context,
  StorageEntry entry,
  VoidCallback onChanged,
) async {
  final destPath = '${_parentOf(entry.path)}/${entry.name}.zip';
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(const SnackBar(content: Text('Compressing…')));

  try {
    await ArchiveService()
        .compressToZip(sourcePaths: [entry.path], destZipPath: destPath);
    onChanged();
    messenger.showSnackBar(
      SnackBar(content: Text('Created ${entry.name}.zip')),
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text("Couldn't compress: $e")));
  }
}

Future<void> _openAsArchive(
  BuildContext context,
  StorageEntry entry,
  VoidCallback onChanged,
) async {
  final service = ArchiveService();
  final messenger = ScaffoldMessenger.of(context);

  if (!service.canExtract(entry.name)) {
    messenger.showSnackBar(const SnackBar(
      content: Text(
        'Only ZIP is supported right now — RAR/7z are coming with full '
        'Archive Support.',
      ),
    ));
    return;
  }

  final folderName = entry.name.substring(0, entry.name.length - 4);
  final destDir = '${_parentOf(entry.path)}/$folderName';
  messenger.showSnackBar(const SnackBar(content: Text('Extracting…')));

  try {
    await service.extractZip(zipPath: entry.path, destDir: destDir);
    onChanged();
    messenger.showSnackBar(SnackBar(content: Text('Extracted to $folderName')));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text("Couldn't extract: $e")));
  }
}
