import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/storage_entry.dart';

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      selected: selected,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.25),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectionMode) ...[
            Checkbox(value: selected, onChanged: (_) => onTap?.call()),
            const SizedBox(width: 4),
          ],
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: entry.iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(entry.icon, color: Colors.white, size: 22),
          ),
        ],
      ),
      title: Text(
        entry.name,
        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${entry.subtitle}   •   ${_dateFormat.format(entry.modified)}',
        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
