import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class EditorScreen extends StatefulWidget {
  final File file;
  const EditorScreen({super.key, required this.file});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      final content = await widget.file.readAsString();
      _controller.text = content;
    } catch (e) {
      debugPrint('Error reading file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFile() async {
    try {
      await widget.file.writeAsString(_controller.text);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File saved')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(p.basename(widget.file.path)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveFile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
