import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/storage_entry.dart';

/// Full-screen image viewer. Takes every image in the current folder so
/// the person can swipe between them, not just the one they tapped.
class ImageViewerScreen extends StatefulWidget {
  final List<StorageEntry> images;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.images[_index];

    // Decode at roughly the screen's physical pixel width instead of the
    // photo's full resolution (often 3000-4000px+ from a modern camera).
    // This is what actually fixes the multi-second open delay — the UI
    // can't show more detail than the screen anyway, so decoding to full
    // resolution every time was pure wasted work.
    final cacheWidth =
        (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio)
            .round()
            .clamp(1, 2000)
            .toInt();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(current.name, overflow: TextOverflow.ellipsis),
            if (widget.images.length > 1)
              Text(
                '${_index + 1} / ${widget.images.length}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _index = i),
        // Lets PageView start building the neighbouring pages immediately,
        // so the next/previous image is already decoding while the
        // current one is still on screen — swiping feels instant instead
        // of each swipe triggering a fresh decode.
        allowImplicitScrolling: true,
        itemBuilder: (context, i) {
          final entry = widget.images[i];
          return InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: Image.file(
                File(entry.path),
                fit: BoxFit.contain,
                cacheWidth: cacheWidth,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
