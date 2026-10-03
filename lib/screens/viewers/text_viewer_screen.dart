import 'dart:io';
import 'package:flutter/material.dart';
import 'fe_text_editor_screen.dart';

class TextViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const TextViewerScreen({
    super.key,
    required this.path,
    required this.title,
  });

  @override
  State<TextViewerScreen> createState() => _TextViewerScreenState();
}

class _TextViewerScreenState extends State<TextViewerScreen> {
  // Bigger than this isn't a "quick preview" anymore.
  static const _maxBytes = 2 * 1024 * 1024;

  String? _content;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final file = File(widget.path);
      final length = await file.length();
      if (length > _maxBytes) {
        if (!mounted) return;
        setState(() =>
            _error = 'This file is too large to preview here (over 2 MB).');
        return;
      }
      final text = await file.readAsString();
      if (!mounted) return;
      setState(() => _content = text);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "Couldn't read this file as text.");
    }
  }

  void _openInEditor() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => FeTextEditorScreen(path: widget.path, title: widget.title),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<void>(
            tooltip: 'More',
            itemBuilder: (context) => [
              PopupMenuItem<void>(
                onTap: _openInEditor,
                child: const ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('FE Text Editor'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : _content == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    _content!,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
    );
  }
}
