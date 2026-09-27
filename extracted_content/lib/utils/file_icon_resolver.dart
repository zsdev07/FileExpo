import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FileIconResolver {
  FileIconResolver._();

  static const _images = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp'};
  static const _videos = {'mp4', 'mkv', 'mov', 'avi', 'webm', '3gp'};
  static const _audio = {'mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac'};
  static const _docs = {'pdf', 'doc', 'docx', 'txt', 'md', 'rtf'};
  static const _sheets = {'xls', 'xlsx', 'csv'};
  static const _archives = {'zip', 'rar', '7z', 'tar', 'gz'};

  static ({IconData icon, Color color}) forFolder() =>
      (icon: Icons.folder_rounded, color: AppColors.folderBlue);

  static ({IconData icon, Color color}) forFile(String fileName) {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';

    if (ext == 'apk') {
      return (icon: Icons.android_rounded, color: AppColors.apkGreen);
    }
    if (_images.contains(ext)) {
      return (icon: Icons.image_rounded, color: Colors.pink.shade400);
    }
    if (_videos.contains(ext)) {
      return (icon: Icons.movie_rounded, color: AppColors.folderTeal);
    }
    if (_audio.contains(ext)) {
      return (icon: Icons.audiotrack_rounded, color: Colors.orange.shade700);
    }
    if (_docs.contains(ext)) {
      return (icon: Icons.description_rounded, color: AppColors.docBlue);
    }
    if (_sheets.contains(ext)) {
      return (icon: Icons.table_chart_rounded, color: Colors.green.shade700);
    }
    if (_archives.contains(ext)) {
      return (icon: Icons.folder_zip_rounded, color: AppColors.archiveBrown);
    }
    return (icon: Icons.insert_drive_file_rounded, color: Colors.blueGrey);
  }
}
