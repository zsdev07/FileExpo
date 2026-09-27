import 'package:flutter/material.dart';

/// Horizontal, tappable path trail like "INTERNAL MEMORY > DCIM > CAMERA"
/// in the reference screenshots. The last segment is highlighted as the
/// current location; earlier ones jump back up the tree.
class BreadcrumbBar extends StatelessWidget {
  final List<String> segments;
  final ValueChanged<int>? onSegmentTap;

  const BreadcrumbBar({
    super.key,
    required this.segments,
    this.onSegmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: segments.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
        ),
        itemBuilder: (context, index) {
          final isLast = index == segments.length - 1;
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: isLast ? null : () => onSegmentTap?.call(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Center(
                child: Text(
                  segments[index].toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(
                    letterSpacing: 0.5,
                    color: isLast ? scheme.primary : scheme.onSurfaceVariant,
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
