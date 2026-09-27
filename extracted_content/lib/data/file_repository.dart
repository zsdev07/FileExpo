import '../models/storage_entry.dart';

abstract class FileRepository {
  /// Lists the immediate children of [path]. Throws a [FileSystemException]
  /// (from `dart:io`) if the path can't be read (missing permission,
  /// deleted mid-browse, etc.) — callers should catch and surface that.
  Future<List<StorageEntry>> list(String path);
}
