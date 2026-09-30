enum FileKind { image, video, audio, text, other }

/// Decides which built-in viewer (if any) a file should open in, purely
/// from its extension — the same lightweight approach [FileIconResolver]
/// uses for icons.
class FileKindResolver {
  FileKindResolver._();

  static const _images = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'bmp'};
  static const _videos = {'mp4', 'mkv', 'mov', 'avi', 'webm', '3gp'};
  static const _audio = {'mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac'};
  static const _text = {
    'txt', 'md', 'json', 'log', 'yaml', 'yml', 'xml', 'csv',
    'dart', 'py', 'js', 'ts', 'html', 'css', 'java', 'kt',
    'c', 'cpp', 'h', 'sh', 'gradle', 'properties', 'ini', 'conf',
  };

  static FileKind resolve(String fileName) {
    final ext =
        fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    if (_images.contains(ext)) return FileKind.image;
    if (_videos.contains(ext)) return FileKind.video;
    if (_audio.contains(ext)) return FileKind.audio;
    if (_text.contains(ext)) return FileKind.text;
    return FileKind.other;
  }
}
