import 'package:flutter/material.dart';
import '../../widgets/coming_soon_tile.dart';

class FilesFoldersSettingsScreen extends StatelessWidget {
  const FilesFoldersSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Files & Folders')),
      body: ListView(
        children: const [
          ComingSoonTile(
            icon: Icons.visibility_off_outlined,
            color: Colors.blueGrey,
            label: 'Hidden items',
            subtitle:
                'Show or hide hidden files, folders, and protected system drives',
          ),
          ComingSoonTile(
            icon: Icons.extension_outlined,
            color: Colors.indigo,
            label: 'File extensions',
            subtitle: 'Always show or hide known file extensions',
          ),
          ComingSoonTile(
            icon: Icons.straighten_outlined,
            color: Colors.teal,
            label: 'Folder sizes',
            subtitle: 'Calculate and show full folder sizes inline',
          ),
          ComingSoonTile(
            icon: Icons.home_outlined,
            color: Colors.deepOrange,
            label: 'Default launch path',
            subtitle: 'Set a custom startup directory',
          ),
        ],
      ),
    );
  }
}
