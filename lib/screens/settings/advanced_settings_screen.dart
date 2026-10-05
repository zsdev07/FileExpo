import 'package:flutter/material.dart';
import '../../widgets/coming_soon_tile.dart';

class AdvancedSettingsScreen extends StatelessWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced & Integration')),
      body: ListView(
        children: const [
          ComingSoonTile(
            icon: Icons.folder_special_outlined,
            color: Colors.green,
            label: 'Default file manager',
            subtitle: "Set FileExpo as the system's default file handler",
          ),
          ComingSoonTile(
            icon: Icons.menu_outlined,
            color: Colors.orange,
            label: 'Context menu',
            subtitle: 'Customize right-click / long-press menu items',
          ),
          ComingSoonTile(
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
