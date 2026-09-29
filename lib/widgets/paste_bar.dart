import 'package:flutter/material.dart';

/// Bottom pill offering to paste the pending clipboard selection into the
/// current folder, plus a quick "new folder here" shortcut. Lives in
/// Scaffold's `bottomNavigationBar` slot so the FAB automatically shifts
/// above it instead of overlapping it.
class PasteBar extends StatelessWidget {
  final int count;
  final VoidCallback onPaste;
  final VoidCallback onNewFolder;

  const PasteBar({
    super.key,
    required this.count,
    required this.onPaste,
    required this.onNewFolder,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Material(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onPaste,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.content_paste_rounded, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      count == 1 ? 'PASTE' : 'PASTE $count ITEMS',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'New folder here',
                    icon: Icon(
                      Icons.create_new_folder_outlined,
                      color: scheme.onPrimaryContainer,
                    ),
                    onPressed: onNewFolder,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
