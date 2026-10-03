import 'package:flutter/material.dart';
import '../../services/zip_listing_service.dart';
import '../../utils/file_size_formatter.dart';

class ZipPreviewScreen extends StatefulWidget {
  final String path;
  final String title;

  const ZipPreviewScreen({
    super.key,
    required this.path,
    required this.title,
  });

  @override
  State<ZipPreviewScreen> createState() => _ZipPreviewScreenState();
}

class _ZipPreviewScreenState extends State<ZipPreviewScreen> {
  final _service = ZipListingService();
  bool _loading = true;
  String? _error;
  List<ZipEntryInfo> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await _service.listEntries(widget.path);
      entries.sort((a, b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, overflow: TextOverflow.ellipsis),
            if (!_loading && _error == null)
              Text(
                '${_entries.length} entr${_entries.length == 1 ? 'y' : 'ies'}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      "Couldn't preview this archive: $_error",
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _entries.isEmpty
                  ? const Center(child: Text('This archive is empty'))
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return ListTile(
                          leading: Icon(
                            entry.isDirectory
                                ? Icons.folder_rounded
                                : Icons.insert_drive_file_rounded,
                          ),
                          title: Text(
                            entry.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: entry.isDirectory
                              ? null
                              : Text(
                                  FileSizeFormatter.format(entry.uncompressedSize),
                                ),
                        );
                      },
                    ),
    );
  }
}
