import 'package:flutter/material.dart';
import '../../services/launch_intent_service.dart';
import '../../widgets/coming_soon_tile.dart';

class AdvancedSettingsScreen extends StatelessWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced & Integration')),
      body: ListView(
        children: [
          const _SectionHeader('Default file manager'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              "Android doesn't have one \"set as default\" switch for file "
              'managers the way it does for browsers. Instead, FileExpo is '
              'registered to appear whenever another app asks how to open '
              'or receive a file — and whatever you pick there with '
              '"Always" is what sticks.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const _StepRow(
            number: 1,
            text: 'Open any file from another app — a download in your '
                'browser, an attachment in your email.',
          ),
          const _StepRow(
            number: 2,
            text: 'When Android asks "Open with", choose FileExpo.',
          ),
          const _StepRow(
            number: 3,
            text: 'Tap "Always" to make FileExpo the default for that type '
                'of file.',
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new_rounded),
            title: const Text('Open FileExpo app settings'),
            subtitle: const Text(
              'See or clear the defaults you\'ve set — look for "Open by '
              'default"',
            ),
            onTap: () => LaunchIntentService().openAppInfoSettings(),
          ),
          const Divider(height: 32),
          const _SectionHeader('Menus & shortcuts'),
          const ComingSoonTile(
            icon: Icons.menu_outlined,
            color: Colors.orange,
            label: 'Context menu',
            subtitle: 'Customize right-click / long-press menu items',
          ),
          const ComingSoonTile(
            icon: Icons.keyboard_outlined,
            color: Colors.redAccent,
            label: 'Keyboard shortcuts',
            subtitle: 'View and reassign hotkeys for navigation',
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
