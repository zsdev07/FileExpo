import 'package:flutter/material.dart';

class SelectionActionBar extends StatelessWidget {
  final VoidCallback onCut;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  /// Null disables the button (e.g. Share when a folder is selected,
  /// Rename when more than one item is selected).
  final VoidCallback? onShare;
  final VoidCallback? onRename;

  final VoidCallback onMore;

  const SelectionActionBar({
    super.key,
    required this.onCut,
    required this.onCopy,
    required this.onDelete,
    required this.onShare,
    required this.onRename,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'Cut',
                  icon: const Icon(Icons.cut_rounded),
                  onPressed: onCut,
                ),
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: onCopy,
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: onDelete,
                ),
                IconButton(
                  tooltip: 'Share',
                  icon: const Icon(Icons.share_outlined),
                  onPressed: onShare,
                ),
                IconButton(
                  tooltip: 'Rename',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onRename,
                ),
                IconButton(
                  tooltip: 'More',
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: onMore,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
