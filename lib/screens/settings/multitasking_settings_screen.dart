import 'package:flutter/material.dart';
import '../../services/settings_store.dart';
import '../../widgets/coming_soon_tile.dart';

class MultitaskingSettingsScreen extends StatelessWidget {
  const MultitaskingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        final store = SettingsStore.instance;
        return Scaffold(
          appBar: AppBar(title: const Text('MultiTasking & Navigation')),
          body: ListView(
            children: [
              const _SectionHeader('Tabs & Panes'),
              SwitchListTile(
                title: const Text('Enable tabs'),
                subtitle: const Text(
                  'Browse multiple folders at once, each in its own tab. '
                  "Changes how the app's main screen works — applies "
                  'immediately, no restart needed.',
                ),
                value: store.tabsEnabled,
                onChanged: (value) => store.setTabsEnabled(value),
              ),
              if (store.tabsEnabled)
                SwitchListTile(
                  title: const Text('Remember open tabs'),
                  subtitle: const Text(
                    'Reopen the same tabs, at the same folders, next time '
                    'you launch FileExpo',
                  ),
                  value: store.sessionRestoreEnabled,
                  onChanged: (value) => store.setSessionRestoreEnabled(value),
                ),
              const ComingSoonTile(
                icon: Icons.vertical_split_outlined,
                color: Colors.blue,
                label: 'Dual-pane layout',
                subtitle: 'Two folders side by side for easy copy/move',
              ),
              const Divider(height: 32),
              const _SectionHeader('Startup Behavior'),
              const ComingSoonTile(
                icon: Icons.rocket_launch_outlined,
                color: Colors.purple,
                label: 'Launch on system startup',
                subtitle: 'Needs a closer look before building — see notes',
              ),
              const ComingSoonTile(
                icon: Icons.open_in_new_outlined,
                color: Colors.teal,
                label: 'New instance vs. new tab',
                subtitle:
                    'For folders opened from other apps — depends on tabs '
                    'above',
              ),
            ],
          ),
        );
      },
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
