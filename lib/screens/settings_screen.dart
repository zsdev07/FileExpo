import 'package:flutter/material.dart';
import 'advanced_settings_screen.dart';
import 'appearance_settings_screen.dart';
import 'files_folders_settings_screen.dart';
import 'multitasking_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _CategoryTile(
            icon: Icons.palette_outlined,
            color: Colors.deepPurple,
            title: 'Appearance & Customization',
            subtitle: 'Themes, Recycle Bin, colors, layout',
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const AppearanceSettingsScreen(),
            )),
          ),
          _CategoryTile(
            icon: Icons.folder_outlined,
            color: Colors.blue.shade700,
            title: 'Files & Folders',
            subtitle: 'Hidden items, extensions, folder sizes, startup path',
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const FilesFoldersSettingsScreen(),
            )),
          ),
          _CategoryTile(
            icon: Icons.view_column_outlined,
            color: Colors.teal.shade700,
            title: 'MultiTasking & Navigation',
            subtitle: 'Tabs, panes, session restore, startup behavior',
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const MultitaskingSettingsScreen(),
            )),
          ),
          _CategoryTile(
            icon: Icons.tune_outlined,
            color: Colors.blueGrey.shade700,
            title: 'Advanced & Integration',
            subtitle: 'Default file manager, context menu, shortcuts',
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const AdvancedSettingsScreen(),
            )),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
