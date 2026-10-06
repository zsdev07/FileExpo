import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/storage_entry.dart';
import '../services/folder_size_service.dart';
import '../services/settings_store.dart';
import '../utils/file_size_formatter.dart';

class StorageEntryTile extends StatelessWidget {
  final StorageEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// When true, a checkbox is shown next to the icon and [selected]
  /// controls whether it's checked (multi-select mode).
  final bool selectionMode;
  final bool selected;

  static final _dateFormat = DateFormat('dd-MMM-yyyy, h:mm a');

  const StorageEntryTile({
    super.key,
    required this.entry,
    this.onTap,
    this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
  });

  /// Strips a known extension for display only (Settings > Files & Folders
  /// > "Hide file extensions") — the actual file on disk, and everywhere
  /// else that uses `entry.name`, is unaffected.
  String get _displayName {
    if (entry.isFolder || !SettingsStore.instance.hideFileExtensions) {
      return entry.name;
    }
    final dot = entry.name.lastIndexOf('.');
    // dot <= 0 covers both "no extension" and a dotfile like ".bashrc"
    // where there's nothing meaningful left to show if stripped.
    if (dot <= 0) return entry.name;
    return entry.name.substring(0, dot);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final compact = SettingsStore.instance.compactView;
    final iconSize = compact ? 34.0 : 44.0;
    final formattedDate = _dateFormat.format(entry.modified);

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      selected: selected,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.25),
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 0 : 4,
      ),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectionMode) ...[
            Checkbox(value: selected, onChanged: (_) => onTap?.call()),
            const SizedBox(width: 4),
          ],
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: entry.iconBackground,
              borderRadius: BorderRadius.circular(compact ? 10 : 14),
            ),
            child: Icon(entry.icon, color: Colors.white, size: compact ? 18 : 22),
          ),
        ],
      ),
      title: Text(
        _displayName,
        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: entry.isFolder && SettingsStore.instance.showFolderSizes
          ? _FolderSizeSubtitle(path: entry.path, formattedDate: formattedDate)
          : Text(
              '${entry.subtitle}   •   $formattedDate',
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}

/// Lazily computes and shows a folder's total size via [FolderSizeService],
/// which caches by path so scrolling the list doesn't restart the scan.
class _FolderSizeSubtitle extends StatelessWidget {
  final String path;
  final String formattedDate;

  const _FolderSizeSubtitle({required this.path, required this.formattedDate});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<int>(
      future: FolderSizeService().calculate(path),
      builder: (context, snapshot) {
        final sizeText = snapshot.hasData
            ? FileSizeFormatter.format(snapshot.data!)
            : 'Calculating…';
        return Text(
          '$sizeText   •   $formattedDate',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
