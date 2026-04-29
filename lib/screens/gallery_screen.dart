import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path/path.dart' as p;

class GalleryScreen extends StatelessWidget {
  final File imageFile;
  const GalleryScreen({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(p.basename(imageFile.path)),
      ),
      body: Center(
        child: Hero(
          tag: imageFile.path,
          child: PhotoView(
            imageProvider: FileImage(imageFile),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        ),
      ),
    );
  }
}
