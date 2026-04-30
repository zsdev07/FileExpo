import 'package:flutter/foundation.dart';
import 'package:ftpconnect/ftpconnect.dart';
import '../models/storage_node.dart';

class NetworkService extends ChangeNotifier {
  FTPConnect? _ftpClient;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<bool> connectFTP(String host, String user, String pass, {int port = 21}) async {
    try {
      _ftpClient = FTPConnect(host, user: user, pass: pass, port: port);
      await _ftpClient!.connect();
      _isConnected = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('FTP Connection Error: $e');
      return false;
    }
  }

  Future<void> disconnectFTP() async {
    await _ftpClient?.disconnect();
    _ftpClient = null;
    _isConnected = false;
    notifyListeners();
  }

  Future<List<StorageNode>> listFTPFiles(String path) async {
    if (_ftpClient == null) return [];
    try {
      await _ftpClient!.changeDirectory(path);
      final list = await _ftpClient!.listDirectoryContent();
      return list.map((f) => StorageNode(
        id: f.name, // In FTP list, name is usually used for path navigation
        name: f.name,
        isDirectory: f.type == FTPEntryType.DIR,
        size: f.size ?? 0,
        modified: f.modifyTime ?? DateTime.now(),
        source: StorageSource.ftp,
      )).toList();
    } catch (e) {
      debugPrint('FTP List Error: $e');
      return [];
    }
  }
}
