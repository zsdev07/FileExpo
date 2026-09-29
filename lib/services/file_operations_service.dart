import 'dart:io';

/// Real filesystem mutations backing the long-press context menu (Rename,
/// Delete, Copy/Cut → Paste). Every destination path is de-duplicated
/// against what's already there, so pasting "photo.jpg" into a folder that
/// already has one produces "photo (1).jpg" instead of overwriting it.
class FileOperationsService {
  Future<void> rename(String path, String newName) async {
    final parent = _parentOf(path);
    final newPath = '$parent/$newName';
    if (await FileSystemEntity.isDirectory(path)) {
      await Directory(path).rename(newPath);
    } else {
      await File(path).rename(newPath);
    }
  }

  Future<void> delete(String path) async {
    if (await FileSystemEntity.isDirectory(path)) {
      await Directory(path).delete(recursive: true);
    } else {
      await File(path).delete();
    }
  }

  /// Copies [sourcePath] into [destDirPath], returning the final path used
  /// (which may differ from the source's name if there was a collision).
  Future<String> copy(String sourcePath, String destDirPath) async {
    final name = _nameOf(sourcePath);
    final destPath = await _uniqueDestPath(destDirPath, name);

    if (await FileSystemEntity.isDirectory(sourcePath)) {
      await _copyDirectory(Directory(sourcePath), Directory(destPath));
    } else {
      await File(sourcePath).copy(destPath);
    }
    return destPath;
  }

  /// Moves [sourcePath] into [destDirPath]. Tries a plain rename first
  /// (instant, works whenever source/destination are on the same volume —
  /// the common case on Android internal storage) and falls back to
  /// copy-then-delete only if that fails (e.g. crossing storage volumes).
  Future<String> move(String sourcePath, String destDirPath) async {
    final name = _nameOf(sourcePath);
    final destPath = await _uniqueDestPath(destDirPath, name);
    final isDir = await FileSystemEntity.isDirectory(sourcePath);

    try {
      if (isDir) {
        await Directory(sourcePath).rename(destPath);
      } else {
        await File(sourcePath).rename(destPath);
      }
      return destPath;
    } catch (_) {
      final copiedPath = await copy(sourcePath, destDirPath);
      if (isDir) {
        await Directory(sourcePath).delete(recursive: true);
      } else {
        await File(sourcePath).delete();
      }
      return copiedPath;
    }
  }

  Future<void> createFolder(String parentDir, String name) async {
    final path = await _uniqueDestPath(parentDir, name);
    await Directory(path).create(recursive: true);
  }

  Future<void> _copyDirectory(Directory source, Directory dest) async {
    await dest.create(recursive: true);
    await for (final child in source.list(recursive: false)) {
      final target = '${dest.path}/${_nameOf(child.path)}';
      if (child is Directory) {
        await _copyDirectory(child, Directory(target));
      } else if (child is File) {
        await child.copy(target);
      }
    }
  }

  Future<String> _uniqueDestPath(String destDir, String name) async {
    if (!await _exists('$destDir/$name')) return '$destDir/$name';

    String base = name;
    String ext = '';
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex > 0) {
      base = name.substring(0, dotIndex);
      ext = name.substring(dotIndex);
    }

    var counter = 1;
    var candidate = '$destDir/$base ($counter)$ext';
    while (await _exists(candidate)) {
      counter++;
      candidate = '$destDir/$base ($counter)$ext';
    }
    return candidate;
  }

  Future<bool> _exists(String path) async {
    final type = await FileSystemEntity.type(path);
    return type != FileSystemEntityType.notFound;
  }

  String _nameOf(String path) => path.split('/').where((s) => s.isNotEmpty).last;

  String _parentOf(String path) {
    final idx = path.lastIndexOf('/');
    return idx <= 0 ? '/' : path.substring(0, idx);
  }
}
