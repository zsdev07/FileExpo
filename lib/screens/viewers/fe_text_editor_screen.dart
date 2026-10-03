import 'dart:io';
import 'package:flutter/material.dart';

/// The first of FileExpo's own "FE" editors — Text now, with Image/Video/
/// Audio editors planned to follow the same naming pattern. Reached from
/// [TextViewerScreen]'s preview via its overflow menu, not opened directly
/// on tap, so editing is always a deliberate second step.
class FeTextEditorScreen extends StatefulWidget {
  final String path;
  final String title;

  const FeTextEditorScreen({
    super.key,
    required this.path,
    required this.title,
  });

  @override
  State<FeTextEditorScreen> createState() => _FeTextEditorScreenState();
}

class _FeTextEditorScreenState extends State<FeTextEditorScreen> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _originalText = '';

  bool get _hasChanges => _controller.text != _originalText;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final text = await File(widget.path).readAsString();
      if (!mounted) return;
      setState(() {
        _originalText = text;
        _controller.text = text;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't open this file for editing: $e";
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await File(widget.path).writeAsString(_controller.text);
      if (!mounted) return;
      setState(() {
        _originalText = _controller.text;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Couldn't save: $e")));
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved edits.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.title, overflow: TextOverflow.ellipsis),
              const Text('FE Text Editor', style: TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            if (!_loading && _error == null)
              IconButton(
                tooltip: 'Save',
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                onPressed: (_saving || !_hasChanges) ? null : _save,
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      decoration: const InputDecoration(border: InputBorder.none),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
      ),
    );
  }
}
