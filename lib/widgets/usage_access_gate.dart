import 'package:flutter/material.dart';

/// Full-screen prompt shown until the user grants "Usage access" — a
/// special Android permission (separate from All Files Access) needed for
/// both per-app storage stats and last-used timestamps.
class UsageAccessGate extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onGrantAccess;

  const UsageAccessGate({
    super.key,
    required this.title,
    required this.message,
    required this.onGrantAccess,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.apps_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onGrantAccess,
              child: const Text('Open settings'),
            ),
          ],
        ),
      ),
    );
  }
}
