import 'package:flutter/material.dart';
import '../models/storage_entry.dart';
import '../services/app_manager_service.dart';
import '../utils/file_kind.dart';
import 'viewers/audio_viewer_screen.dart';
import 'viewers/image_viewer_screen.dart';
import 'viewers/text_viewer_screen.dart';
import 'viewers/video_viewer_screen.dart';
import 'viewers/zip_preview_screen.dart';

/// Opens a file FileExpo was launched with (from another app's "Open
/// with" or "Share") in the matching built-in viewer. For a type with no
/// viewer it does nothing — the normal file browser is already underneath,
/// so the person isn't left stranded.
void openExternalFile(BuildContext context, String path) {
  final name = path.split('/').where((s) => s.isNotEmpty).last;
  final navigator = Navigator.of(context);

  switch (FileKindResolver.resolve(name)) {
    case FileKind.image:
      final entry = StorageEntry(
        name: name,
        type: StorageEntryType.file,
        path: path,
        subtitle: '',
        modified: DateTime.now(),
        icon: Icons.image_rounded,
        iconBackground: Colors.pink,
      );
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => ImageViewerScreen(images: [entry], initialIndex: 0),
      ));
      break;
    case FileKind.video:
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => VideoViewerScreen(path: path, title: name),
      ));
      break;
    case FileKind.audio:
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => AudioViewerScreen(path: path, title: name),
      ));
      break;
    case FileKind.text:
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => TextViewerScreen(path: path, title: name),
      ));
      break;
    case FileKind.zipArchive:
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => ZipPreviewScreen(path: path, title: name),
      ));
      break;
    case FileKind.apk:
      AppManagerService().installApk(path).then((error) {
        if (error == null || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't open installer: $error")),
        );
      });
      break;
    case FileKind.other:
      break;
  }
}
