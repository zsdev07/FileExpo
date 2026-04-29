import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../services/security_service.dart';
import '../services/file_service.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityService>();
    final fileService = context.watch<FileService>();

    if (!security.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Safe Folder')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 100, color: Colors.grey),
              const SizedBox(height: 20),
              const Text('This folder is protected'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => security.authenticate(),
                child: const Text('Unlock with Biometrics'),
              ),
            ],
          ),
        ),
      );
    }

    final vaultDir = Directory(security.vaultPath);
    final entities = vaultDir.listSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Folder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => security.logout(),
          ),
        ],
      ),
      body: entities.isEmpty
          ? const Center(child: Text('Safe Folder is empty'))
          : ListView.builder(
              itemCount: entities.length,
              itemBuilder: (context, index) {
                final entity = entities[index];
                return ListTile(
                  leading: Icon(
                    entity is Directory ? Icons.folder : Icons.insert_drive_file,
                    color: entity is Directory ? Colors.amber : Colors.blueGrey,
                  ),
                  title: Text(p.basename(entity.path)),
                  trailing: IconButton(
                    icon: const Icon(Icons.outbox),
                    tooltip: 'Remove from Vault',
                    onPressed: () async {
                      await security.removeFromVault(entity, '/storage/emulated/0');
                      fileService.refresh();
                      (context as Element).markNeedsBuild(); // Refresh local list
                    },
                  ),
                );
              },
            ),
    );
  }
}
