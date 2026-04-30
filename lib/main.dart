import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'screens/main_navigation.dart';
import 'services/file_service.dart';
import 'services/tab_service.dart';
import 'services/storage_service.dart';
import 'services/app_service.dart';
import 'services/root_service.dart';
import 'services/cloud_service.dart';
import 'services/network_service.dart';
import 'services/web_server_service.dart';
import 'services/security_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FileService()),
        ChangeNotifierProvider(create: (_) => TabService()),
        ChangeNotifierProvider(create: (_) => StorageService()),
        ChangeNotifierProvider(create: (_) => AppService()),
        ChangeNotifierProvider(create: (_) => RootService()),
        ChangeNotifierProvider(create: (_) => CloudService()),
        ChangeNotifierProvider(create: (_) => NetworkService()),
        ChangeNotifierProvider(create: (_) => WebServerService()),
        ChangeNotifierProvider(create: (_) => SecurityService()),
      ],
      child: const FileExpoApp(),
    ),
  );
}

Future<void> _requestPermissions() async {
  if (Platform.isAndroid) {
    // Android 11+ needs MANAGE_EXTERNAL_STORAGE via special settings page
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
    // Fallback for Android 10 and below
    await Permission.storage.request();
  }
}

class FileExpoApp extends StatelessWidget {
  const FileExpoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FileExpo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainNavigation(),
    );
  }
}
