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

/// Holds at most one pending copy/cut target so the "Paste" bar can appear
/// anywhere in the file browser. Deliberately a plain in-memory singleton —
/// clipboard contents never need to survive an app restart.
class ClipboardService extends ChangeNotifier {
  ClipboardService._internal();
  static final ClipboardService instance = ClipboardService._internal();

  ClipboardEntry? _entry;
  ClipboardEntry? get entry => _entry;

  void setCopy(StorageEntry source) {
    _entry = ClipboardEntry(
      path: source.path,
      name: source.name,
      isCut: false,
      isDirectory: source.isFolder,
    );
    notifyListeners();
  }

  void setCut(StorageEntry source) {
    _entry = ClipboardEntry(
      path: source.path,
      name: source.name,
      isCut: true,
      isDirectory: source.isFolder,
    );
    notifyListeners();
  }

  void clear() {
    _entry = null;
    notifyListeners();
  }
}
