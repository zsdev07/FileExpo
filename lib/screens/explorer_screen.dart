import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../services/tab_service.dart';
import '../services/file_service.dart';
import '../widgets/explorer_pane.dart';

class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({super.key});

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _extensionFilter = '';
  
  @override
  Widget build(BuildContext context) {
    final tabService = context.watch<TabService>();
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FileExpo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_to_photos),
            onPressed: () => tabService.addTab(Directory('/storage/emulated/0'), 'New Tab'),
          ),
        ],
        bottom: isLandscape ? _buildTabBar(context, tabService) : null,
      ),
      body: isLandscape 
          ? Row(
              children: [
                Expanded(child: ExplorerPane(tabIndex: tabService.activeTabIndex)),
                const VerticalDivider(width: 1),
                Expanded(child: ExplorerPane(tabIndex: tabService.secondaryTabIndex)),
              ],
            )
          : ExplorerPane(tabIndex: tabService.activeTabIndex),
      drawer: isLandscape ? null : _buildDrawer(context, tabService),
    );
  }

  PreferredSizeWidget _buildTabBar(BuildContext context, TabService tabService) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: Container(
        height: 50,
        color: Theme.of(context).colorScheme.surface,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: tabService.tabs.length,
          itemBuilder: (context, index) {
            final isSelected = tabService.activeTabIndex == index;
            final isSecondary = tabService.secondaryTabIndex == index;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(p.basename(tabService.tabs[index].directory.path).isEmpty 
                    ? 'Root' 
                    : p.basename(tabService.tabs[index].directory.path)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) tabService.setActiveTab(index);
                },
                avatar: isSecondary ? const Icon(Icons.looks_two, size: 16) : null,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, TabService tabService) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(child: Text('Tabs', style: TextStyle(fontSize: 24))),
          for (int i = 0; i < tabService.tabs.length; i++)
            ListTile(
              title: Text(tabService.tabs[i].name),
              subtitle: Text(tabService.tabs[i].directory.path),
              selected: tabService.activeTabIndex == i,
              onTap: () {
                tabService.setActiveTab(i);
                Navigator.pop(context);
              },
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => tabService.removeTab(i),
              ),
            ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advanced Search'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Search by name...'),
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => _extensionFilter = v,
              decoration: const InputDecoration(hintText: 'Extension (e.g. .jpg)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performSearch(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _performSearch(BuildContext context) {
    final results = context.read<FileService>().searchFiles(
      query: _searchController.text,
      extension: _extensionFilter,
    );
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (_, controller) => ListView.builder(
          controller: controller,
          itemCount: results.length,
          itemBuilder: (context, index) {
            final entity = results[index];
            return ListTile(
              leading: Icon(entity is Directory ? Icons.folder : Icons.insert_drive_file),
              title: Text(p.basename(entity.path)),
              subtitle: Text(entity.path),
              onTap: () {
                Navigator.pop(context);
                // Handle navigation to result
              },
            );
          },
        ),
      ),
    );
  }
}
