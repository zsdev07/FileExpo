import 'dart:io';
import '../utils/storage_category.dart';

class LargeFileEntry {
  final String path;
  final String name;
  final int size;
  final DateTime modified;

  const LargeFileEntry({
    required this.path,
    required this.name,
    required this.size,
    required this.modified,
  });
}

class ScanResult {
  final Map<StorageCategoryKind, int> categoryBytes;
  final Map<StorageCategoryKind, int> categoryCounts;

  /// Every file found in each category (not just the largest) — backs the
  /// category drill-down screen.
  final Map<StorageCategoryKind, List<LargeFileEntry>> categoryFiles;
  final List<LargeFileEntry> largestFiles;
  final int scannedBytes;
  final int scannedFiles;

  const ScanResult({
    required this.categoryBytes,
    required this.categoryCounts,
    required this.categoryFiles,
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
    final categoryFiles = <StorageCategoryKind, List<LargeFileEntry>>{
      for (final k in StorageCategoryKind.values) k: <LargeFileEntry>[],
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
          FileStat stat;
          try {
            stat = await child.stat();
          } catch (_) {
            continue;
          }

          final kind = StorageCategoryResolver.resolve(name);
          categoryBytes[kind] = (categoryBytes[kind] ?? 0) + stat.size;
          categoryCounts[kind] = (categoryCounts[kind] ?? 0) + 1;
          scannedBytes += stat.size;
          scannedFiles++;

          final fileEntry = LargeFileEntry(
            path: child.path,
            name: name,
            size: stat.size,
            modified: stat.modified,
          );
          categoryFiles[kind]!.add(fileEntry);

          largest.add(fileEntry);
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
      categoryFiles: categoryFiles,
      largestFiles: largest,
      scannedBytes: scannedBytes,
      scannedFiles: scannedFiles,
    );
  }
}
