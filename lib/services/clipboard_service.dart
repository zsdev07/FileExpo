import 'package:flutter/foundation.dart';
import '../models/storage_entry.dart';

class ClipboardEntry {
  final String path;
  final String name;
  final bool isCut;
  final bool isDirectory;

  const ClipboardEntry({
    required this.path,
    required this.name,
    required this.isCut,
    required this.isDirectory,
  });
}

/// Holds the pending copy/cut selection so a "Paste" bar can appear
/// anywhere in the file browser. Plain in-memory singleton — clipboard
/// contents never need to survive an app restart. Supports multiple
/// entries at once (multi-select Cut/Copy).
class ClipboardService extends ChangeNotifier {
  ClipboardService._internal();
  static final ClipboardService instance = ClipboardService._internal();

  List<ClipboardEntry> _entries = [];
  List<ClipboardEntry> get entries => List.unmodifiable(_entries);
  bool get isEmpty => _entries.isEmpty;
  int get length => _entries.length;

  void setEntries(List<StorageEntry> sources, {required bool isCut}) {
    _entries = sources
        .map((s) => ClipboardEntry(
              path: s.path,
              name: s.name,
              isCut: isCut,
              isDirectory: s.isFolder,
            ))
        .toList();
    notifyListeners();
  }

  void clear() {
    _entries = [];
    notifyListeners();
  }
}
