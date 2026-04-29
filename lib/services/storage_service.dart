import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class StorageService extends ChangeNotifier {
  Map<String, double> _storageStats = {
    'Images': 0,
    'Videos': 0,
    'Audio': 0,
    'Documents': 0,
    'Archives': 0,
    'Other': 0,
  };
  
  List<File> _largeFiles = [];
  List<File> _junkFiles = [];
  bool _isAnalyzing = false;
  double _totalSize = 0;

  Map<String, double> get storageStats => _storageStats;
  List<File> get largeFiles => _largeFiles;
  List<File> get junkFiles => _junkFiles;
  bool get isAnalyzing => _isAnalyzing;
  double get totalSize => _totalSize;

  Future<void> analyzeStorage() async {
    _isAnalyzing = true;
    _totalSize = 0;
    _storageStats.updateAll((key, value) => 0);
    _largeFiles.clear();
    _junkFiles.clear();
    notifyListeners();

    try {
      final dir = Directory('/storage/emulated/0');
      if (await dir.exists()) {
        await for (var entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            final size = entity.lengthSync().toDouble();
            _totalSize += size;
            _categorizeFile(entity, size);
            
            // Large files > 100MB
            if (size > 100 * 1024 * 1024) {
              _largeFiles.add(entity);
            }

            // Junk detection (temp files, cache)
            final ext = p.extension(entity.path).toLowerCase();
            if (ext == '.tmp' || ext == '.log' || entity.path.contains('/cache/')) {
              _junkFiles.add(entity);
            }
          }
        }
        _largeFiles.sort((a, b) => b.lengthSync().compareTo(a.lengthSync()));
      }
    } catch (e) {
      debugPrint('Error analyzing storage: $e');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void _categorizeFile(File file, double size) {
    final ext = p.extension(file.path).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
      _storageStats['Images'] = (_storageStats['Images'] ?? 0) + size;
    } else if (['.mp4', '.mkv', '.mov', '.avi'].contains(ext)) {
      _storageStats['Videos'] = (_storageStats['Videos'] ?? 0) + size;
    } else if (['.mp3', '.wav', '.m4a', '.ogg'].contains(ext)) {
      _storageStats['Audio'] = (_storageStats['Audio'] ?? 0) + size;
    } else if (['.pdf', '.doc', '.docx', '.txt', '.xlsx'].contains(ext)) {
      _storageStats['Documents'] = (_storageStats['Documents'] ?? 0) + size;
    } else if (['.zip', '.rar', '.7z', '.tar'].contains(ext)) {
      _storageStats['Archives'] = (_storageStats['Archives'] ?? 0) + size;
    } else {
      _storageStats['Other'] = (_storageStats['Other'] ?? 0) + size;
    }
  }

  Future<void> cleanJunk() async {
    for (var file in _junkFiles) {
      try {
        await file.delete();
      } catch (e) {
        debugPrint('Failed to delete junk: ${file.path}');
      }
    }
    _junkFiles.clear();
    notifyListeners();
  }
}
