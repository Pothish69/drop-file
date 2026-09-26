import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() {
  runApp(const PhoneShareApp());
}

class PhoneShareApp extends StatelessWidget {
  const PhoneShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Phone Share',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HttpServer? server;

  bool serverRunning = false;
  String serverAddress = '';

  // ==========================================
  // START SERVER
  // ==========================================

  Future<void> startServer() async {
    Future<Response> handler(Request request) async {
      // ==========================================
      // FILE UPLOAD API
      // ==========================================

      if (request.method == 'POST' && request.url.path == 'upload') {
        try {
          // Get file name from browser
          final fileName = request.headers['x-file-name'];

          if (fileName == null || fileName.isEmpty) {
            return Response.badRequest(body: 'File name is missing');
          }

          // Folder where files will be saved
          final directory = Directory(
            '/storage/emulated/0/Download/PhoneShare',
          );

          // Create folder if it doesn't exist
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }

          // Create file
          final file = File('${directory.path}/$fileName');

          // Read uploaded file
          final bytes = await request.read().expand((chunk) => chunk).toList();

          // Save file
          await file.writeAsBytes(bytes);

          // Print information in Flutter terminal
          print('Uploaded file: ${file.path}');

          print('File size: ${bytes.length} bytes');

          return Response.ok('File uploaded successfully!');
        } catch (e) {
          print('UPLOAD ERROR: $e');

          return Response.internalServerError(body: 'Upload failed: $e');
        }
      }

      // ==========================================
      // WEB PAGE
      // ==========================================

      final html = await rootBundle.loadString('assets/web/index.html');

      return Response.ok(html, headers: {'Content-Type': 'text/html'});
      // Return web page

    }

    // ==========================================
    // START HTTP SERVER
    // ==========================================

    server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);

    // ==========================================
    // FIND PHONE IP ADDRESS
    // ==========================================

    final interfaces = await NetworkInterface.list();

    String? ipAddress;

    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
          ipAddress = address.address;

          break;
        }
      }

      if (ipAddress != null) {
        break;
      }
    }

    // ==========================================
    // UPDATE UI
    // ==========================================

    setState(() {
      serverRunning = true;

      serverAddress = 'http://$ipAddress:8080';
    });
  }

  // ==========================================
  // STOP SERVER
  // ==========================================

  Future<void> stopServer() async {
    await server?.close();

    setState(() {
      serverRunning = false;

      serverAddress = '';
    });
  }

  // ==========================================
  // CLEANUP
  // ==========================================

  @override
  void dispose() {
    server?.close();

    super.dispose();
  }

  // ==========================================
  // FLUTTER APP UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Share'), centerTitle: true),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              // SERVER ICON
              Icon(
                serverRunning ? Icons.wifi : Icons.wifi_off,

                size: 80,

                color: serverRunning ? Colors.green : Colors.grey,
              ),

              const SizedBox(height: 20),

              // SERVER STATUS
              Text(
                serverRunning ? 'Server Running' : 'Server Stopped',

                style: const TextStyle(
                  fontSize: 24,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // SERVER ADDRESS
              if (serverRunning)
                Text(
                  serverAddress,

                  style: const TextStyle(
                    fontSize: 18,

                    fontWeight: FontWeight.bold,
                  ),
                ),

              const SizedBox(height: 30),

              // START / STOP BUTTON
              ElevatedButton(
                onPressed: serverRunning ? stopServer : startServer,

                child: Text(serverRunning ? 'Stop Server' : 'Start Server'),
              ),

              const SizedBox(height: 20),

              // INFORMATION
              const Text(
                'Make sure your phone and laptop\n'
                'are connected to the same Wi-Fi',

                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
