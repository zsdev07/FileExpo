import 'package:flutter/material.dart';
import '../../services/settings_store.dart';
import '../../widgets/coming_soon_tile.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        final store = SettingsStore.instance;
        return Scaffold(
          appBar: AppBar(title: const Text('Appearance & Customization')),
          body: ListView(
            children: [
              const _SectionHeader('Theme'),
              RadioListTile<AppThemeMode>(
                title: const Text('Light'),
                value: AppThemeMode.light,
                groupValue: store.themeMode,
                onChanged: (value) => store.setThemeMode(value!),
              ),
              RadioListTile<AppThemeMode>(
                title: const Text('Dark'),
                value: AppThemeMode.dark,
                groupValue: store.themeMode,
                onChanged: (value) => store.setThemeMode(value!),
              ),
              RadioListTile<AppThemeMode>(
                title: const Text('Follow system'),
                value: AppThemeMode.system,
                groupValue: store.themeMode,
                onChanged: (value) => store.setThemeMode(value!),
              ),
              const Divider(height: 32),

              const _SectionHeader('Recycle Bin'),
              SwitchListTile(
                title: const Text('Enable Recycle Bin'),
                subtitle: const Text(
                  'Deleted files move to trash instead of being removed '
                  'immediately. This setting is saved now — the trash '
                  'behavior itself arrives in the next drop.',
                ),
                value: store.recycleBinEnabled,
                onChanged: (value) => store.setRecycleBinEnabled(value),
              ),
              if (store.recycleBinEnabled)
                ListTile(
                  title: const Text('Keep deleted files for'),
                  trailing: DropdownButton<int>(
                    value: store.recycleBinRetentionDays,
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7 days')),
                      DropdownMenuItem(value: 30, child: Text('30 days')),
                    ],
                    onChanged: (value) {
                      if (value != null) store.setRecycleBinRetentionDays(value);
                    },
                  ),
                ),
              const Divider(height: 32),

              const _SectionHeader('Backdrop & Colors'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < kAccentColorOptions.length; i++)
                      _AccentSwatch(
                        option: kAccentColorOptions[i],
                        selected: store.accentColorIndex == i,
                        onTap: () => store.setAccentColorIndex(i),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  store.accentColorIndex == 0
                      ? 'Purple matches your wallpaper automatically on '
                          'Android 12+ (Material You). Pick another color '
                          'to override that.'
                      : 'Overriding Material You — pick Purple again to go '
                          'back to automatic wallpaper matching.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              const ComingSoonTile(
                icon: Icons.gradient_outlined,
                color: Colors.deepPurple,
                label: 'Background transparency',
                subtitle: 'Blur/transparency effects behind content',
              ),
              const ComingSoonTile(
                icon: Icons.wallpaper_outlined,
                color: Colors.indigo,
                label: 'Wallpaper integration',
                subtitle: 'Pull accent colors straight from your wallpaper',
              ),
              const Divider(height: 32),

              const _SectionHeader('Layout & Icons'),
              SwitchListTile(
                title: const Text('Compact view'),
                subtitle: const Text('Smaller rows, more files per screen'),
                value: store.compactView,
                onChanged: (value) => store.setCompactView(value),
              ),
              const ComingSoonTile(
                icon: Icons.text_fields_rounded,
                color: Colors.teal,
                label: 'Font size',
                subtitle: 'Adjust text size across the app',
              ),
              const ComingSoonTile(
                icon: Icons.widgets_outlined,
                color: Colors.brown,
                label: 'Custom icon sets',
                subtitle: 'Alternate icon packs for files and folders',
              ),
              const SizedBox(height: 16),
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

class _AccentSwatch extends StatelessWidget {
  final AccentColorOption option;
  final bool selected;
  final VoidCallback onTap;

  const _AccentSwatch({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: option.seed,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 4),
          Text(option.label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
