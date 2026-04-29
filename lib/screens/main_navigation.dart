import 'package:flutter/material.dart';
import 'explorer_screen.dart';
import 'dashboard_screen.dart';
import 'app_manager_screen.dart';
import 'connections_screen.dart';
import 'vault_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ExplorerScreen(),
    const DashboardScreen(),
    const AppManagerScreen(),
    const ConnectionsScreen(),
    const VaultScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.folder), label: 'Explorer'),
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.apps), label: 'Apps'),
          NavigationDestination(icon: Icon(Icons.cloud), label: 'Connect'),
          NavigationDestination(icon: Icon(Icons.security), label: 'Vault'),
        ],
      ),
    );
  }
}
