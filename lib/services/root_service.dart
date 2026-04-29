import 'dart:io';
import 'package:flutter/foundation.dart';

class RootService extends ChangeNotifier {
  bool _isRootEnabled = false;
  bool _hasRootAccess = false;

  bool get isRootEnabled => _isRootEnabled;
  bool get hasRootAccess => _hasRootAccess;

  Future<void> checkRoot() async {
    try {
      final result = await Process.run('su', ['-c', 'id']);
      _hasRootAccess = result.exitCode == 0;
    } catch (e) {
      _hasRootAccess = false;
    }
    notifyListeners();
  }

  void toggleRoot(bool value) {
    _isRootEnabled = value;
    if (_isRootEnabled) checkRoot();
    notifyListeners();
  }

  Future<List<String>> listDirectory(String path) async {
    if (!_isRootEnabled || !_hasRootAccess) return [];
    try {
      final result = await Process.run('su', ['-c', 'ls -1 $path']);
      if (result.exitCode == 0) {
        return (result.stdout as String).split('\n').where((s) => s.isNotEmpty).toList();
      }
    } catch (e) {
      debugPrint('Root listing error: $e');
    }
    return [];
  }
}
