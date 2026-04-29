import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cloud_service.dart';
import '../services/network_service.dart';
import 'web_share_screen.dart';

class ConnectionsScreen extends StatelessWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cloud = context.watch<CloudService>();
    final network = context.watch<NetworkService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cloud & Network')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Wi-Fi Sharing'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.wifi_tethering, color: Colors.blue),
              title: const Text('Transfer to PC'),
              subtitle: const Text('Share files via web browser over Wi-Fi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WebShareScreen())),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Cloud Services'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.add_to_drive, color: Colors.green),
              title: const Text('Google Drive'),
              subtitle: Text(cloud.isSignedIn ? 'Logged in as ${cloud.currentUser?.email}' : 'Connect your account'),
              trailing: ElevatedButton(
                onPressed: cloud.isSignedIn ? () => cloud.signOut() : () => cloud.signIn(),
                child: Text(cloud.isSignedIn ? 'Logout' : 'Login'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Network Protocols'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lan, color: Colors.orange),
              title: const Text('FTP Server'),
              subtitle: Text(network.isConnected ? 'Connected to FTP' : 'Access remote servers'),
              trailing: ElevatedButton(
                onPressed: () => _showFTPDialog(context),
                child: Text(network.isConnected ? 'Disconnect' : 'Connect'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  void _showFTPDialog(BuildContext context) {
    final hostController = TextEditingController();
    final userController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect to FTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: hostController, decoration: const InputDecoration(hintText: 'Host (e.g. 192.168.1.10)')),
            TextField(controller: userController, decoration: const InputDecoration(hintText: 'Username')),
            TextField(controller: passController, decoration: const InputDecoration(hintText: 'Password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await context.read<NetworkService>().connectFTP(
                hostController.text,
                userController.text,
                passController.text,
              );
              if (success) Navigator.pop(context);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}
