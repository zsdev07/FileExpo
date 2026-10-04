import 'dart:io';

enum ApkFileType { apk, xapk }

class ApkFileEntry {
  final String path;
  final String name;
  final int size;
  final DateTime modified;
  final ApkFileType type;

  const ApkFileEntry({
    required this.path,
    required this.name,
    required this.size,
    required this.modified,
    required this.type,
  });
}

/// Finds every .apk/.xapk file on storage. Deliberately separate from the
/// full category scan in [StorageScanService] — the Installer screen wants
/// a quick, focused two-extension search, not a whole-device size
/// breakdown across every file type.
class ApkScanService {
  Future<List<ApkFileEntry>> scan(String rootPath) async {
    final results = <ApkFileEntry>[];

    Future<void> walk(Directory dir) async {
      List<FileSystemEntity> children;
      try {
        children = await dir.list(recursive: false).toList();
      } catch (_) {
        return; // restricted / unreadable — skip quietly
      }

      for (final child in children) {
        final name = child.path.split('/').where((s) => s.isNotEmpty).last;
        if (name.startsWith('.')) continue;

        if (child is Directory) {
          await walk(child);
        } else if (child is File) {
          final lower = name.toLowerCase();
          ApkFileType? type;
          if (lower.endsWith('.apk')) {
            type = ApkFileType.apk;
          } else if (lower.endsWith('.xapk')) {
            type = ApkFileType.xapk;
          }
          if (type == null) continue;

          try {
            final stat = await child.stat();
            results.add(ApkFileEntry(
              path: child.path,
              name: name,
              size: stat.size,
              modified: stat.modified,
              type: type,
            ));
          } catch (_) {
            continue;
          }
        }
      }
    }

    await walk(Directory(rootPath));
    results.sort((a, b) => b.modified.compareTo(a.modified)); // newest first
    return results;
  }
}
