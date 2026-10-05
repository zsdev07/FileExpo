import 'package:flutter/material.dart';
import '../../widgets/coming_soon_tile.dart';

class MultitaskingSettingsScreen extends StatelessWidget {
  const MultitaskingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MultiTasking & Navigation')),
      body: ListView(
        children: const [
          ComingSoonTile(
            icon: Icons.tab_outlined,
            color: Colors.blue,
            label: 'Tabs & panes',
            subtitle: 'Multi-tab behavior, session restore, dual-pane layout',
          ),
          ComingSoonTile(
            icon: Icons.rocket_launch_outlined,
            color: Colors.purple,
            label: 'Startup behavior',
            subtitle:
                'Launch on system startup, new instance vs. new tab for '
                'external folders',
          ),
        ],
      ),
    );
  }
}
