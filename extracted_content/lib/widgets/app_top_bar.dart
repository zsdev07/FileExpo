import 'package:flutter/material.dart';

/// The rounded "pill" header seen at the top of the reference screenshots:
/// menu icon, title + item-count subtitle, search icon, overflow menu.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onMoreTap;

  const AppTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.onMenuTap,
    this.onSearchTap,
    this.onMoreTap,
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
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: onMenuTap,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: onSearchTap,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: onMoreTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
