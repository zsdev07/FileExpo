import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';
import '../services/root_service.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final root = context.watch<RootService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Analyzer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => storage.analyzeStorage(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRootToggle(context, root),
              const SizedBox(height: 20),
              if (storage.isAnalyzing)
                const Center(child: CircularProgressIndicator())
              else ...[
                _buildStorageChart(storage),
                const SizedBox(height: 30),
                _buildJunkCard(context, storage),
                const SizedBox(height: 30),
                _buildLargeFilesList(storage),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRootToggle(BuildContext context, RootService root) {
    return Card(
      child: SwitchListTile(
        title: const Text('Root Mode'),
        subtitle: Text(root.isRootEnabled 
            ? (root.hasRootAccess ? 'Access Granted' : 'Access Denied (Check SU)') 
            : 'Access System Files'),
        value: root.isRootEnabled,
        onChanged: (value) => root.toggleRoot(value),
        secondary: const Icon(Icons.security),
      ),
    );
  }

  Widget _buildStorageChart(StorageService storage) {
    final data = storage.storageStats.entries.where((e) => e.value > 0).toList();
    if (data.isEmpty) return const Center(child: Text('Start analysis to see distribution'));

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sections: data.asMap().entries.map((entry) {
            final index = entry.key;
            final val = entry.value;
            final color = Colors.primaries[index % Colors.primaries.length];
            return PieChartSectionData(
              color: color,
              value: val.value,
              title: '${val.key}\n${_formatSize(val.value)}',
              radius: 100,
              titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildJunkCard(BuildContext context, StorageService storage) {
    final junkCount = storage.junkFiles.length;
    return Card(
      color: Colors.red.withOpacity(0.1),
      child: ListTile(
        leading: const Icon(Icons.cleaning_services, color: Colors.red),
        title: const Text('Smart Cleaner'),
        subtitle: Text('$junkCount junk files identified'),
        trailing: ElevatedButton(
          onPressed: junkCount > 0 ? () => storage.cleanJunk() : null,
          child: const Text('Clean'),
        ),
      ),
    );
  }

  Widget _buildLargeFilesList(StorageService storage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Large Files (>100MB)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: storage.largeFiles.length.clamp(0, 10),
          itemBuilder: (context, index) {
            final file = storage.largeFiles[index];
            return ListTile(
              leading: const Icon(Icons.file_present),
              title: Text(p.basename(file.path)),
              subtitle: Text(file.path),
              trailing: Text(_formatSize(file.lengthSync().toDouble()), style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          },
        ),
      ],
    );
  }

  String _formatSize(double bytes) {
    if (bytes < 1024) return '${bytes.toInt()} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
