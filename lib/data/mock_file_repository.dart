import 'package:flutter/material.dart';
import '../models/storage_entry.dart';
import '../theme/app_colors.dart';
import 'file_repository.dart';

/// Sample data used only by the step-1 UI shell / previews. The real app
/// (see [RealFileRepository]) reads `dart:io` directories instead.
class MockFileRepository implements FileRepository {
  const MockFileRepository();

  @override
  Future<List<StorageEntry>> list(String path) async => rootFolders();


  List<StorageEntry> rootFolders() {
    final now = DateTime.now();
    return [
      StorageEntry(
        name: 'Android',
        type: StorageEntryType.folder,
        path: '/storage/emulated/0/Android',
        subtitle: '4 items',
        modified: now.subtract(const Duration(days: 29)),
        icon: Icons.folder_rounded,
        iconBackground: AppColors.folderTeal,
      ),
      StorageEntry(
        name: 'DCIM',
        type: StorageEntryType.folder,
        path: '/storage/emulated/0/DCIM',
        subtitle: '3 items',
        modified: now.subtract(const Duration(days: 88)),
        icon: Icons.camera_alt_rounded,
        iconBackground: AppColors.folderBlue,
      ),
      StorageEntry(
        name: 'Documents',
        type: StorageEntryType.folder,
        path: '/storage/emulated/0/Documents',
        subtitle: '6 items',
        modified: now.subtract(const Duration(days: 13)),
        icon: Icons.description_rounded,
        iconBackground: AppColors.docBlue,
      ),
      StorageEntry(
        name: 'Download',
        type: StorageEntryType.folder,
        path: '/storage/emulated/0/Download',
        subtitle: '17 items',
        modified: now,
        icon: Icons.download_rounded,
        iconBackground: AppColors.folderBlue,
      ),
      StorageEntry(
        name: 'Movies',
        type: StorageEntryType.folder,
        path: '/storage/emulated/0/Movies',
        subtitle: '5 items',
        modified: now.subtract(const Duration(days: 19)),
        icon: Icons.movie_rounded,
        iconBackground: AppColors.folderTeal,
      ),
      StorageEntry(
        name: 'Music',
        type: StorageEntryType.folder,
        path: '/storage/emulated/0/Music',
        subtitle: '2 items',
        modified: now.subtract(const Duration(days: 330)),
        icon: Icons.audiotrack_rounded,
        iconBackground: AppColors.folderTeal,
      ),
    ];
  }
}
