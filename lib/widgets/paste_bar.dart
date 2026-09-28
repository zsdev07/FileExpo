import 'package:flutter/material.dart';
import '../services/clipboard_service.dart';

class PasteBar extends StatelessWidget {
  final ClipboardEntry entry;
  final VoidCallback onPaste;
  final VoidCallback onCancel;

  const PasteBar({
    super.key,
    required this.entry,
    required this.onPaste,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Icon(
                entry.isCut ? Icons.cut_rounded : Icons.copy_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${entry.isCut ? "Move" : "Copy"} "${entry.name}" here',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(onPressed: onCancel, child: const Text('Cancel')),
              const SizedBox(width: 4),
              FilledButton(onPressed: onPaste, child: const Text('Paste')),
            ],
          ),
        ),
      ),
    );
  }
}
