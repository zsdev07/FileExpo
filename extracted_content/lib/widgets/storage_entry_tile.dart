import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/storage_entry.dart';

class StorageEntryTile extends StatelessWidget {
  final StorageEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  static final _dateFormat = DateFormat('dd-MMM-yyyy, h:mm a');

  const StorageEntryTile({
    super.key,
    required this.entry,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: entry.iconBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(entry.icon, color: Colors.white, size: 22),
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
