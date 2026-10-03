import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class ZipEntryInfo {
  final String name;
  final int compressedSize;
  final int uncompressedSize;
  final bool isDirectory;

  const ZipEntryInfo({
    required this.name,
    required this.compressedSize,
    required this.uncompressedSize,
    required this.isDirectory,
  });
}

class ZipListingException implements Exception {
  final String message;
  ZipListingException(this.message);

  @override
  String toString() => message;
}

/// Lists a ZIP's contents by reading just its central directory —
/// deliberately not using `package:archive` (or any decompression) here.
/// The central directory is a plain index of names/sizes sitting at the
/// end of the file; none of the actual (DEFLATE-compressed) file content
/// needs to be touched just to answer "what's in this archive", which is
/// what keeps this both dependency-free and fast even on large archives.
///
/// Known limitation: ZIP64 (archives over ~4GB, or with 65535+ entries)
/// isn't handled — [listEntries] throws a [ZipListingException] for those
/// rather than returning wrong sizes.
class ZipListingService {
  static const _cdHeaderSignature = 0x02014b50;
  static const _maxEocdSearch = 65557; // 22-byte EOCD + max 65535-byte comment

  Future<List<ZipEntryInfo>> listEntries(String path) async {
    final file = File(path);
    final length = await file.length();
    if (length < 22) {
      throw ZipListingException('Not a valid ZIP file.');
    }
    final searchLength = length < _maxEocdSearch ? length : _maxEocdSearch;

    final raf = await file.open();
    try {
      await raf.setPosition(length - searchLength);
      final tail = await raf.read(searchLength);

      final eocdOffset = _findEocd(tail);
      if (eocdOffset < 0) {
        throw ZipListingException('Not a recognizable ZIP file.');
      }

      final eocd = ByteData.sublistView(tail, eocdOffset);
      final totalEntries = eocd.getUint16(10, Endian.little);
      final cdSize = eocd.getUint32(12, Endian.little);
      final cdOffset = eocd.getUint32(16, Endian.little);

      if (cdOffset == 0xFFFFFFFF || cdSize == 0xFFFFFFFF) {
        throw ZipListingException("ZIP64 archives aren't supported yet.");
      }

      await raf.setPosition(cdOffset);
      final centralDirBytes = await raf.read(cdSize);
      return _parseCentralDirectory(centralDirBytes, totalEntries);
    } finally {
      await raf.close();
    }
  }

  /// The EOCD record can be followed by a variable-length comment, so it
  /// isn't necessarily the very last 22 bytes — scan backwards for its
  /// signature instead of assuming a fixed position.
  int _findEocd(Uint8List tail) {
    for (var i = tail.length - 22; i >= 0; i--) {
      if (tail[i] == 0x50 &&
          tail[i + 1] == 0x4b &&
          tail[i + 2] == 0x05 &&
          tail[i + 3] == 0x06) {
        return i;
      }
    }
    return -1;
  }

  List<ZipEntryInfo> _parseCentralDirectory(
    Uint8List bytes,
    int totalEntries,
  ) {
    final entries = <ZipEntryInfo>[];
    final data = ByteData.sublistView(bytes);
    var offset = 0;

    for (var i = 0; i < totalEntries; i++) {
      if (offset + 46 > bytes.length) break;
      final signature = data.getUint32(offset, Endian.little);
      if (signature != _cdHeaderSignature) break;

      final compressedSize = data.getUint32(offset + 20, Endian.little);
      final uncompressedSize = data.getUint32(offset + 24, Endian.little);
      final nameLength = data.getUint16(offset + 28, Endian.little);
      final extraLength = data.getUint16(offset + 30, Endian.little);
      final commentLength = data.getUint16(offset + 32, Endian.little);

      final nameStart = offset + 46;
      if (nameStart + nameLength > bytes.length) break;
      final nameBytes = bytes.sublist(nameStart, nameStart + nameLength);
      final name = utf8.decode(nameBytes, allowMalformed: true);

      entries.add(ZipEntryInfo(
        name: name,
        compressedSize: compressedSize,
        uncompressedSize: uncompressedSize,
        isDirectory: name.endsWith('/'),
      ));

      offset = nameStart + nameLength + extraLength + commentLength;
    }
    return entries;
  }
}
