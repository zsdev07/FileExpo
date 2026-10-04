import 'package:flutter/material.dart';

/// Reusable disabled/"Soon" row for a feature that's listed but not wired
/// up yet — visibly inert rather than pretending to work. Used across the
/// Storage Analyzer and the Settings screens.
class ComingSoonTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final EdgeInsetsGeometry? contentPadding;

  const ComingSoonTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: 0.55,
      child: ListTile(
        contentPadding: contentPadding,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(label),
        subtitle: Text(subtitle),
        trailing: Text(
          'Soon',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming soon')),
          );
        },
      ),
    );
  }
}
