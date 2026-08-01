import 'dart:io';

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
    final handler = (Request request) async {
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

      final html = '''
<!DOCTYPE html>

<html>

<head>

  <meta name="viewport"
        content="width=device-width, initial-scale=1.0">

  <title>Phone Share</title>


  <!-- ============================= -->
  <!-- CSS -->
  <!-- ============================= -->

  <style>

    * {
      box-sizing: border-box;
    }

    body {
      font-family: Arial, sans-serif;
      background: #f5f5f5;
      text-align: center;
      padding: 40px 20px;
      margin: 0;
    }

    .container {
      max-width: 600px;
      margin: auto;
      background: white;
      padding: 30px;
      border-radius: 20px;
      box-shadow: 0 5px 20px rgba(0, 0, 0, 0.1);
    }

    h1 {
      margin-bottom: 10px;
    }

    .description {
      color: #666;
    }

    .drop-area {
      margin-top: 30px;
      padding: 50px 20px;
      border: 3px dashed #888;
      border-radius: 15px;
      cursor: pointer;
      transition: 0.2s;
    }

    .drop-area:hover {
      background: #f0f0f0;
      border-color: #2196f3;
    }

    .icon {
      font-size: 50px;
    }

    input[type="file"] {
      margin-top: 15px;
    }

    button {
      margin-top: 20px;
      padding: 12px 30px;
      border: none;
      border-radius: 10px;
      background: #2196f3;
      color: white;
      font-size: 16px;
      cursor: pointer;
    }

    button:hover {
      background: #1976d2;
    }

    button:disabled {
      background: #999;
      cursor: not-allowed;
    }

    #status {
      margin-top: 20px;
      font-weight: bold;
    }

  </style>

</head>


<body>


  <!-- ============================= -->
  <!-- MAIN CONTAINER -->
  <!-- ============================= -->

  <div class="container">

    <h1>📱 Phone Share</h1>

    <p class="description">
      Send files between your devices
    </p>


    <!-- ============================= -->
    <!-- FILE UPLOAD AREA -->
    <!-- ============================= -->

    <div class="drop-area">

      <div class="icon">
        📁
      </div>

      <h2>
        Choose a file
      </h2>

      <p>
        Select a file from your laptop
      </p>


      <!-- FILE INPUT -->

      <input
        type="file"
        id="fileInput"
      >


      <br>


      <!-- UPLOAD BUTTON -->

      <button
        id="uploadButton"
        onclick="uploadFile()"
      >
        Upload File
      </button>


      <!-- STATUS -->

      <p id="status"></p>

    </div>

  </div>


  <!-- ============================= -->
  <!-- JAVASCRIPT -->
  <!-- ============================= -->

  <script>

    async function uploadFile() {

      // Get file input
      const input =
        document.getElementById('fileInput');

      // Get status element
      const status =
        document.getElementById('status');

      // Get upload button
      const button =
        document.getElementById('uploadButton');


      // Check if user selected a file

      if (input.files.length === 0) {

        status.innerText =
          'Please select a file first.';

        return;
      }


      // Get selected file

      const file =
        input.files[0];


      // Show uploading message

      status.innerText =
        'Uploading ' + file.name + '...';


      // Disable button

      button.disabled = true;


      try {

        // Send file to Flutter server

        const response =
          await fetch('/upload', {

            method: 'POST',

            headers: {

              'X-File-Name':
                file.name

            },

            body: file

          });


        // Get server response

        const result =
          await response.text();


        // Check result

        if (response.ok) {

          status.innerText =
            '✅ ' + result;

          // Clear selected file

          input.value = '';

        } else {

          status.innerText =
            '❌ ' + result;

        }


      } catch (error) {

        console.error(error);

        status.innerText =
          '❌ Upload error: ' + error;

      }


      // Enable button again

      button.disabled = false;

    }

  </script>


</body>

</html>
''';

      // Return web page

      return Response.ok(html, headers: {'Content-Type': 'text/html'});
    };

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
