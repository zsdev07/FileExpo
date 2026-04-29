import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive_io.dart';

class FileService extends ChangeNotifier {
  Directory _currentDirectory = Directory('/storage/emulated/0');
  List<FileSystemEntity> _entities = [];
  bool _isLoading = false;
  List<String> _favorites = [];

  // Batch Operations State
  final Set<String> _selectedPaths = {};
  bool _isSelectionMode = false;

  // Copy/Move Clipboard
  List<String> _clipboardPaths = [];
  bool _isCopyMode = true; // true = copy, false = move

  Directory get currentDirectory => _currentDirectory;
  List<FileSystemEntity> get entities => _entities;
  bool get isLoading => _isLoading;
  List<String> get favorites => _favorites;
  Set<String> get selectedPaths => _selectedPaths;
  bool get isSelectionMode => _isSelectionMode;
  bool get hasClipboard => _clipboardPaths.isNotEmpty;

  FileService() {
    _loadFavorites();
    refresh();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favorites = prefs.getStringList('favorites') ?? [];
    notifyListeners();
  }

  // --- Selection & Batch Methods ---

  void toggleSelection(String path) {
    if (_selectedPaths.contains(path)) {
      _selectedPaths.remove(path);
      if (_selectedPaths.isEmpty) _isSelectionMode = false;
    } else {
      _selectedPaths.add(path);
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedPaths.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  // --- Clipboard Methods ---

  void setClipboard(List<String> paths, {required bool isCopy}) {
    _clipboardPaths = paths;
    _isCopyMode = isCopy;
    clearSelection();
    notifyListeners();
  }

  Future<void> paste() async {
    _isLoading = true;
    notifyListeners();

    try {
      for (String path in _clipboardPaths) {
        final entity = FileSystemEntity.typeSync(path) == FileSystemEntityType.file 
            ? File(path) 
            : Directory(path);
        
        String newPath = p.join(_currentDirectory.path, p.basename(path));
        
        if (_isCopyMode) {
          if (entity is File) {
            await entity.copy(newPath);
          } else if (entity is Directory) {
            await _copyDirectory(entity, Directory(newPath));
          }
        } else {
          await entity.rename(newPath);
        }
      }
      if (!_isCopyMode) _clipboardPaths.clear();
      refresh();
    } catch (e) {
      debugPrint('Error pasting: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (var entity in source.list(recursive: false)) {
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(p.join(destination.path, p.basename(entity.path))));
      } else if (entity is File) {
        await entity.copy(p.join(destination.path, p.basename(entity.path)));
      }
    }
  }

  // --- Core Operations ---

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (await Permission.manageExternalStorage.request().isGranted ||
          await Permission.storage.request().isGranted) {
        if (await _currentDirectory.exists()) {
          _entities = _currentDirectory.listSync();
          _entities.sort((a, b) {
            if (a is Directory && b is File) return -1;
            if (a is File && b is Directory) return 1;
            return a.path.toLowerCase().compareTo(b.path.toLowerCase());
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading files: $e');
      _entities = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void navigateTo(Directory directory) {
    _currentDirectory = directory;
    refresh();
  }

  void navigateBack() {
    if (_currentDirectory.path != '/storage/emulated/0' && _currentDirectory.path != '/') {
      _currentDirectory = _currentDirectory.parent;
      refresh();
    }
  }

  Future<void> deleteEntities(List<String> paths) async {
    try {
      for (var path in paths) {
        final entity = FileSystemEntity.typeSync(path) == FileSystemEntityType.file 
            ? File(path) 
            : Directory(path);
        await entity.delete(recursive: true);
      }
      clearSelection();
      refresh();
    } catch (e) {
      debugPrint('Error deleting: $e');
    }
  }

  Future<void> renameEntity(FileSystemEntity entity, String newName) async {
    try {
      String newPath = p.join(entity.parent.path, newName);
      await entity.rename(newPath);
      refresh();
    } catch (e) {
      debugPrint('Error renaming: $e');
    }
  }

  Future<void> createDirectory(String name) async {
    try {
      Directory newDir = Directory(p.join(_currentDirectory.path, name));
      await newDir.create();
      refresh();
    } catch (e) {
      debugPrint('Error creating directory: $e');
    }
  }

  void shareEntities(List<String> paths) {
    Share.shareXFiles(paths.map((p) => XFile(p)).toList());
  }

  // --- Archive Support ---

  Future<void> compressToZip(List<String> paths, String zipName) async {
    _isLoading = true;
    notifyListeners();
    try {
      var encoder = ZipFileEncoder();
      encoder.create(p.join(_currentDirectory.path, '$zipName.zip'));
      for (var path in paths) {
        final type = FileSystemEntity.typeSync(path);
        if (type == FileSystemEntityType.file) {
          encoder.addFile(File(path));
        } else if (type == FileSystemEntityType.directory) {
          encoder.addDirectory(Directory(path));
        }
      }
      encoder.close();
      clearSelection();
      refresh();
    } catch (e) {
      debugPrint('Error zipping: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> extractZip(File zipFile) async {
    _isLoading = true;
    notifyListeners();
    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final outDir = p.join(_currentDirectory.path, p.basenameWithoutExtension(zipFile.path));
      
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File(p.join(outDir, filename))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(p.join(outDir, filename)).createSync(recursive: true);
        }
      }
      refresh();
    } catch (e) {
      debugPrint('Error extracting: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleFavorite(String path) async {
    if (_favorites.contains(path)) {
      _favorites.remove(path);
    } else {
      _favorites.add(path);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);
    notifyListeners();
  }

  // --- Advanced Search ---
  
  List<FileSystemEntity> searchFiles({
    required String query,
    String? extension,
    int? minSize, // in bytes
    int? maxSize, // in bytes
    DateTime? modifiedAfter,
  }) {
    return _entities.where((entity) {
      if (entity is! File) {
        if (query.isNotEmpty && !p.basename(entity.path).toLowerCase().contains(query.toLowerCase())) {
          return false;
        }
        return query.isNotEmpty; // Only show folders if query matches
      }

      final file = entity;
      final name = p.basename(file.path).toLowerCase();
      
      // Name Query
      if (query.isNotEmpty && !name.contains(query.toLowerCase())) return false;
      
      // Extension Filter
      if (extension != null && extension.isNotEmpty) {
        if (!name.endsWith(extension.toLowerCase())) return false;
      }
      
      // Size Filters
      final size = file.lengthSync();
      if (minSize != null && size < minSize) return false;
      if (maxSize != null && size > maxSize) return false;
      
      // Date Filter
      final lastModified = file.lastModifiedSync();
      if (modifiedAfter != null && lastModified.isBefore(modifiedAfter)) return false;

      return true;
    }).toList();
  }
}
