import 'dart:io';

/// Recursively sums a folder's total size, for Settings > Files & Folders
/// > "Show folder sizes". Caches both in-flight and completed calculations
/// so a `ListView` rebuilding the same tile mid-scroll reuses the same
/// Future instead of restarting the scan from scratch each time.
class FolderSizeService {
  static final Map<String, int> _cache = {};
  static final Map<String, Future<int>> _inFlight = {};

  Future<int> calculate(String path) {
    final cached = _cache[path];
    if (cached != null) return Future.value(cached);

    final pending = _inFlight[path];
    if (pending != null) return pending;

    final future = _computeRaw(path).then((total) {
      _cache[path] = total;
      _inFlight.remove(path);
      return total;
    });
    _inFlight[path] = future;
    return future;
  }

  /// Call after any operation that could change a folder's contents
  /// (delete, paste, rename) so sizes recompute instead of showing stale
  /// cached values.
  static void clearCache() {
    _cache.clear();
    _inFlight.clear();
  }

  Future<int> _computeRaw(String path) async {
    var total = 0;

    Future<void> walk(Directory dir) async {
      List<FileSystemEntity> children;
      try {
        children = await dir.list(recursive: false).toList();
      } catch (_) {
        return; // restricted / unreadable — contributes 0, not an error
      }
      for (final child in children) {
        if (child is Directory) {
          await walk(child);
        } else if (child is File) {
          try {
            total += await child.length();
          } catch (_) {
            // skip unreadable file
          }
        }
      }
    }

    await walk(Directory(path));
    return total;
  }
}
