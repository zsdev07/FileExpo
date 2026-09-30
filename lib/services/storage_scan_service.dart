import 'dart:io';
import '../utils/storage_category.dart';

class LargeFileEntry {
  final String path;
  final String name;
  final int size;

  const LargeFileEntry({
    required this.path,
    required this.name,
    required this.size,
  });
}

class ScanResult {
  final Map<StorageCategoryKind, int> categoryBytes;
  final Map<StorageCategoryKind, int> categoryCounts;
  final List<LargeFileEntry> largestFiles;
  final int scannedBytes;
  final int scannedFiles;

  const ScanResult({
    required this.categoryBytes,
    required this.categoryCounts,
    required this.largestFiles,
    required this.scannedBytes,
    required this.scannedFiles,
  });
}

/// Walks the whole storage tree once, bucketing file sizes by category and
/// keeping a running top-N of the largest files. Restricted or unreadable
/// subfolders are skipped quietly rather than aborting the whole scan —
/// a single locked-down system folder shouldn't blank out the results.
class StorageScanService {
  Future<ScanResult> scan(String rootPath, {int topFilesLimit = 20}) async {
    final categoryBytes = <StorageCategoryKind, int>{
      for (final k in StorageCategoryKind.values) k: 0,
    };
    final categoryCounts = <StorageCategoryKind, int>{
      for (final k in StorageCategoryKind.values) k: 0,
    };
    final largest = <LargeFileEntry>[];
    var scannedBytes = 0;
    var scannedFiles = 0;

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
          int size;
          try {
            size = await child.length();
          } catch (_) {
            continue;
          }

          final kind = StorageCategoryResolver.resolve(name);
          categoryBytes[kind] = (categoryBytes[kind] ?? 0) + size;
          categoryCounts[kind] = (categoryCounts[kind] ?? 0) + 1;
          scannedBytes += size;
          scannedFiles++;

          largest.add(LargeFileEntry(path: child.path, name: name, size: size));
          largest.sort((a, b) => b.size.compareTo(a.size));
          if (largest.length > topFilesLimit) {
            largest.removeRange(topFilesLimit, largest.length);
          }
        }
      }
    }

    await walk(Directory(rootPath));

    return ScanResult(
      categoryBytes: categoryBytes,
      categoryCounts: categoryCounts,
      largestFiles: largest,
      scannedBytes: scannedBytes,
      scannedFiles: scannedFiles,
    );
  }
}
