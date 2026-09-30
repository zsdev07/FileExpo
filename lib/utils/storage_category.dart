enum StorageCategoryKind {
  images,
  videos,
  audio,
  documents,
  archives,
  apks,
  other,
}

/// Buckets a file into a broad category for the Storage Analyzer, purely
/// from its extension — same lightweight approach as [FileIconResolver]
/// and [FileKindResolver].
class StorageCategoryResolver {
  StorageCategoryResolver._();

  static const _images = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp'};
  static const _videos = {'mp4', 'mkv', 'mov', 'avi', 'webm', '3gp'};
  static const _audio = {'mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac'};
  static const _documents = {
    'pdf', 'doc', 'docx', 'txt', 'md', 'rtf', 'xls', 'xlsx', 'csv', 'ppt', 'pptx',
  };
  static const _archives = {'zip', 'rar', '7z', 'tar', 'gz'};

  static StorageCategoryKind resolve(String fileName) {
    final ext =
        fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    if (ext == 'apk') return StorageCategoryKind.apks;
    if (_images.contains(ext)) return StorageCategoryKind.images;
    if (_videos.contains(ext)) return StorageCategoryKind.videos;
    if (_audio.contains(ext)) return StorageCategoryKind.audio;
    if (_documents.contains(ext)) return StorageCategoryKind.documents;
    if (_archives.contains(ext)) return StorageCategoryKind.archives;
    return StorageCategoryKind.other;
  }
}
