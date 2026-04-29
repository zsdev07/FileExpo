enum StorageSource { local, googleDrive, ftp }

class StorageNode {
  final String id; // Path for local/ftp, File ID for Google Drive
  final String name;
  final bool isDirectory;
  final int size;
  final DateTime modified;
  final StorageSource source;
  final String? mimeType;

  StorageNode({
    required this.id,
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.modified,
    required this.source,
    this.mimeType,
  });

  String get extension => name.contains('.') ? name.split('.').last.toLowerCase() : '';
}
