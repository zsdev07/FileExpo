import 'package:flutter/material.dart';

class SelectionTopBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedCount;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;
  final VoidCallback onInvertSelection;

  const SelectionTopBar({
    super.key,
    required this.selectedCount,
    required this.onClose,
    required this.onSelectAll,
    required this.onInvertSelection,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Material(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClose,
                ),
                Expanded(
                  child: Text(
                    '$selectedCount item${selectedCount == 1 ? '' : 's'} selected',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Select all',
                  icon: const Icon(Icons.select_all_rounded),
                  onPressed: onSelectAll,
                ),
                IconButton(
                  tooltip: 'Invert selection',
                  icon: const Icon(Icons.flip_to_back_rounded),
                  onPressed: onInvertSelection,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
