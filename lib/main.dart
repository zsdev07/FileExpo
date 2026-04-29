import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

void main() {
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
