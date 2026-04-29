import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../models/storage_node.dart';

class CloudService extends ChangeNotifier {
  GoogleSignInAccount? _currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope, drive.DriveApi.driveReadOnlyScope],
  );

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  Future<void> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      notifyListeners();
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<List<StorageNode>> listDriveFiles(String folderId) async {
    if (_currentUser == null) return [];
    
    final httpClient = (await _googleSignIn.authenticatedClient())!;
    final driveApi = drive.DriveApi(httpClient);
    
    final fileList = await driveApi.files.list(
      q: "'$folderId' in parents and trashed = false",
      $fields: "files(id, name, mimeType, size, modifiedTime)",
    );

    return fileList.files?.map((f) => StorageNode(
      id: f.id!,
      name: f.name!,
      isDirectory: f.mimeType == 'application/vnd.google-apps.folder',
      size: int.tryParse(f.size ?? '0') ?? 0,
      modified: f.modifiedTime ?? DateTime.now(),
      source: StorageSource.googleDrive,
      mimeType: f.mimeType,
    )).toList() ?? [];
  }
}
