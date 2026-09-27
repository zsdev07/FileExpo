import 'package:flutter/material.dart';

enum StorageEntryType { folder, file }

/// A single row in the file browser: either a folder or a file.
///
/// This is intentionally storage-agnostic — step 1 only renders the UI
/// shell with sample data (see `MockFileRepository`). A later step swaps
/// the repository for one backed by `dart:io` + scoped-storage APIs
/// without touching any of the widgets below.
class StorageEntry {
  final String name;
  final StorageEntryType type;
  final String path;

  /// Human readable summary shown under the name, e.g. "12 items" for a
  /// folder or "4.2 MB" for a file.
  final String subtitle;
  final DateTime modified;

  /// Icon + its rounded background color, so different file/folder kinds
  /// (media, archives, apks, docs...) are visually distinct at a glance,
  /// matching the reference screenshots.
  final IconData icon;
  final Color iconBackground;

  const StorageEntry({
    required this.name,
    required this.type,
    required this.path,
    required this.subtitle,
    required this.modified,
    required this.icon,
    required this.iconBackground,
  });

  bool get isFolder => type == StorageEntryType.folder;
}
