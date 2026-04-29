import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path/path.dart' as p;

class WebServerService extends ChangeNotifier {
  HttpServer? _server;
  String? _ipAddress;
  int _port = 8080;
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  String? get serverUrl => _ipAddress != null ? 'http://$_ipAddress:$_port' : null;

  Future<void> startServer() async {
    if (_isRunning) return;

    final info = NetworkInfo();
    _ipAddress = await info.getWifiIP();
    
    if (_ipAddress == null) {
      debugPrint('Could not get Wi-Fi IP');
      return;
    }

    var handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_handleRequest);

    _server = await io.serve(handler, _ipAddress!, _port);
    _isRunning = true;
    notifyListeners();
    debugPrint('Server running at http://$_ipAddress:$_port');
  }

  Future<void> stopServer() async {
    await _server?.close();
    _server = null;
    _isRunning = false;
    notifyListeners();
  }

  Future<Response> _handleRequest(Request request) async {
    final path = Uri.decodeComponent(request.url.path);
    final fullPath = p.join('/storage/emulated/0', path);
    final file = File(fullPath);
    final dir = Directory(fullPath);

    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      return Response.ok(bytes, headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Disposition': 'attachment; filename="${p.basename(fullPath)}"',
      });
    } else if (await dir.exists()) {
      final entities = await dir.list().toList();
      String html = '<html><body><h1>FileExpo Web Share</h1><ul>';
      html += '<li><a href="../">.. (Parent Directory)</a></li>';
      for (var entity in entities) {
        final name = p.basename(entity.path);
        final relativePath = p.relative(entity.path, from: '/storage/emulated/0');
        html += '<li><a href="/$relativePath">$name ${entity is Directory ? '/' : ''}</a></li>';
      }
      html += '</ul></body></html>';
      return Response.ok(html, headers: {'Content-Type': 'text/html'});
    }

    return Response.notFound('Not Found');
  }
}
