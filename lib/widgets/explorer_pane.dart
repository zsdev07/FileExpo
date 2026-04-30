import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../services/file_service.dart';
import '../services/tab_service.dart';
import '../screens/editor_screen.dart';
import '../screens/gallery_screen.dart';
import '../screens/player_screen.dart';
import '../screens/video_player_screen.dart';
import '../screens/pdf_viewer_screen.dart';

class ExplorerPane extends StatelessWidget {
  final int tabIndex;
  const ExplorerPane({super.key, required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    final fileService = context.watch<FileService>();
    final tabService = context.watch<TabService>();
    final tab = tabService.tabs[tabIndex];
    
    final entities = tab.directory.listSync(); 

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: tab.directory.path == '/storage/emulated/0' 
                    ? null 
                    : () => tabService.updateTabPath(tabIndex, tab.directory.parent),
              ),
              Expanded(
                child: Text(
                  tab.directory.path,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: entities.length,
            itemBuilder: (context, index) {
              final entity = entities[index];
              final isDir = entity is Directory;
              final name = p.basename(entity.path);

              return ListTile(
                leading: Icon(
                  isDir ? Icons.folder : _getFileIcon(name),
                  color: isDir ? Colors.amber : Colors.blueGrey,
                ),
                title: Text(name),
                onTap: () {
                  if (isDir) {
                    tabService.updateTabPath(tabIndex, entity);
                  } else {
                    _handleFileClick(context, entity as File);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) return Icons.image;
    if (['.mp3', '.wav', '.m4a', '.ogg'].contains(ext)) return Icons.audiotrack;
    if (['.mp4', '.mkv', '.mov', '.avi'].contains(ext)) return Icons.video_library;
    if (['.txt', '.md', '.json', '.xml'].contains(ext)) return Icons.description;
    if (ext == '.pdf') return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }

  void _handleFileClick(BuildContext context, File file) {
    final ext = p.extension(file.path).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => GalleryScreen(imageFile: file)));
    } else if (['.mp3', '.wav', '.m4a', '.ogg'].contains(ext)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(audioFile: file)));
    } else if (['.mp4', '.mkv', '.mov', '.avi'].contains(ext)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoFile: file)));
    } else if (ext == '.pdf') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewerScreen(pdfFile: file)));
    } else if (['.txt', '.md', '.json', '.xml'].contains(ext)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => EditorScreen(file: file)));
    }
  }
}
