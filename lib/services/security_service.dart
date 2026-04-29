import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

class SecurityService extends ChangeNotifier {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticated = false;
  final String _vaultPath = '/storage/emulated/0/.FileExpoVault';

  bool get isAuthenticated => _isAuthenticated;
  String get vaultPath => _vaultPath;

  SecurityService() {
    _initVault();
  }

  Future<void> _initVault() async {
    final dir = Directory(_vaultPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<bool> authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) return false;

      _isAuthenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to access the Safe Folder',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      notifyListeners();
      return _isAuthenticated;
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  // --- AES Encryption ---

  encrypt.Key _deriveKey(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }

  Future<void> encryptFile(File file, String password) async {
    try {
      final key = _deriveKey(password);
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final fileBytes = await file.readAsBytes();
      final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

      // Save encrypted file with .enc extension
      final encryptedFile = File('${file.path}.enc');
      // Prepend IV to the file for decryption later
      final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);
      await encryptedFile.writeAsBytes(combined);
      
      // Delete original file
      await file.delete();
    } catch (e) {
      debugPrint('Encryption error: $e');
      rethrow;
    }
  }

  Future<void> decryptFile(File encryptedFile, String password) async {
    try {
      final key = _deriveKey(password);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final allBytes = await encryptedFile.readAsBytes();
      final iv = encrypt.IV(allBytes.sublist(0, 16));
      final encryptedBytes = allBytes.sublist(16);

      final decrypted = encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: iv);

      final originalPath = encryptedFile.path.replaceAll('.enc', '');
      await File(originalPath).writeAsBytes(decrypted);

      // Delete encrypted file
      await encryptedFile.delete();
    } catch (e) {
      debugPrint('Decryption error: $e');
      rethrow;
    }
  }

  Future<void> moveToVault(FileSystemEntity entity) async {
    final targetPath = p.join(_vaultPath, p.basename(entity.path));
    await entity.rename(targetPath);
  }

  Future<void> removeFromVault(FileSystemEntity entity, String targetDir) async {
    final targetPath = p.join(targetDir, p.basename(entity.path));
    await entity.rename(targetPath);
  }
}
