import 'dart:io';
import 'package:archive/archive_io.dart';

/// Backs "Compress…" and "Open as archive" in the context menu.
///
/// Only ZIP is implemented today — it's a pure-Dart format the `archive`
/// package handles without any native/platform code, which keeps this safe
/// to ship now. RAR and 7z need proprietary/native codecs and are tracked
/// for the dedicated Archive Support phase; [canExtract] reports that
/// honestly so the UI can say so instead of silently failing.
class ArchiveService {
  Future<String> compressToZip({
    required List<String> sourcePaths,
    required String destZipPath,
  }) async {
    final encoder = ZipFileEncoder();
    encoder.create(destZipPath);
    for (final path in sourcePaths) {
      if (await FileSystemEntity.isDirectory(path)) {
        await encoder.addDirectory(Directory(path), includeDirName: true);
      } else {
        await encoder.addFile(File(path));
      }
    }
    await encoder.close();
    return destZipPath;
  }

  bool canExtract(String fileName) => fileName.toLowerCase().endsWith('.zip');

  Future<String> extractZip({
    required String zipPath,
    required String destDir,
  }) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    await Directory(destDir).create(recursive: true);

    for (final file in archive) {
      final outPath = '$destDir/${file.name}';
      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }
    return destDir;
  }
}
