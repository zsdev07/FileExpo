import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/web_server_service.dart';

class WebShareScreen extends StatelessWidget {
  const WebShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final webServer = context.watch<WebServerService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Wi-Fi File Sharing')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_tethering,
                size: 100,
                color: webServer.isRunning ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 30),
              Text(
                webServer.isRunning ? 'Sharing Active' : 'Sharing Inactive',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Text(
                webServer.isRunning
                    ? 'Open this URL in your PC browser:'
                    : 'Start the server to share files with your PC wirelessly.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (webServer.isRunning) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    webServer.serverUrl ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: webServer.isRunning ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (webServer.isRunning) {
                      webServer.stopServer();
                    } else {
                      webServer.startServer();
                    }
                  },
                  child: Text(webServer.isRunning ? 'Stop Server' : 'Start Server'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
