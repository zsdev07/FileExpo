import 'dart:io';
import '../models/storage_entry.dart';
import '../services/settings_store.dart';
import '../utils/file_icon_resolver.dart';
import '../utils/file_size_formatter.dart';
import 'file_repository.dart';

/// Lists real files/folders from device storage. Hidden entries (dotfiles)
/// are skipped unless Settings > Files & Folders > "Show hidden items" is
/// on; folders are sorted before files, and both groups are sorted
/// case-insensitively by name — matching the reference screenshots.
class RealFileRepository implements FileRepository {
  @override
  Future<List<StorageEntry>> list(String path) async {
    final dir = Directory(path);
    final children = await dir.list().toList();
    final showHidden = SettingsStore.instance.showHiddenItems;

    final entries = <StorageEntry>[];
    for (final child in children) {
      final name = child.path.split('/').where((s) => s.isNotEmpty).last;
      if (!showHidden && name.startsWith('.')) continue;

      final stat = await child.stat();

      if (child is Directory) {
        final itemCount = _countChildrenSafely(child, showHidden);
        final icon = FileIconResolver.forFolder();
        entries.add(StorageEntry(
          name: name,
          type: StorageEntryType.folder,
          path: child.path,
          subtitle: itemCount == null
              ? 'Restricted'
              : '$itemCount item${itemCount == 1 ? '' : 's'}',
          modified: stat.modified,
          icon: icon.icon,
          iconBackground: icon.color,
        ));
      } else {
        final icon = FileIconResolver.forFile(name);
        entries.add(StorageEntry(
          name: name,
          type: StorageEntryType.file,
          path: child.path,
          subtitle: FileSizeFormatter.format(stat.size),
          modified: stat.modified,
          icon: icon.icon,
          iconBackground: icon.color,
        ));
      }
    }

    entries.sort((a, b) {
      if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }

  /// Counting a folder's contents means listing it, which can throw
  /// (permission-restricted system folders like `Android/data` on newer
  /// OS versions) — treat that as "restricted" rather than crashing the
  /// whole listing.
  int? _countChildrenSafely(Directory directory, bool showHidden) {
    try {
      return directory
          .listSync()
          .where((e) => showHidden || !e.path.split('/').last.startsWith('.'))
          .length;
    } catch (_) {
      return null;
    }
  }
}
