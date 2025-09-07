import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Satellite Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TestImagePage(),
    );
  }
}

class TestImagePage extends StatefulWidget {
  const TestImagePage({super.key});

  @override
  State<TestImagePage> createState() => _TestImagePageState();
}

class _TestImagePageState extends State<TestImagePage> {
  String? originalImageUrl;
  String? annotatedImageUrl;
  bool loading = false;
  String? errorMessage;
  String serverStatus = 'Non connecté';

  // Testez différentes URLs selon votre plateforme
  final List<String> baseUrls = [
    "http://10.0.2.2:5000", // Android Emulator
    "http://localhost:5000", // iOS Simulator
    "http://192.168.1.100:5000", // Remplacez par votre IP locale
    "http://127.0.0.1:5000",
  ];

  int currentUrlIndex = 0;
  String get baseUrl => baseUrls[currentUrlIndex];

  @override
  void initState() {
    super.initState();
    _checkServerStatus();
  }

  Future<void> _checkServerStatus() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/")).timeout(
        const Duration(seconds: 3),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          serverStatus = 'Connecté';
          errorMessage = null;
        });
      }
    } catch (e) {
      _tryNextUrl();
    }
  }

  void _tryNextUrl() {
    if (currentUrlIndex < baseUrls.length - 1) {
      setState(() {
        currentUrlIndex++;
        serverStatus = 'Essai de connexion...';
      });
      _checkServerStatus();
    } else {
      setState(() {
        serverStatus = 'Serveur non trouvé';
        errorMessage = 'Impossible de se connecter au serveur Flask. Assurez-vous qu\'il est démarré sur le port 5000.';
      });
    }
  }

  Future<void> captureImage() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/capture_image"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: "lat=32.9297&lon=10.4518&zoom=17",
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["status"] == "success") {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          setState(() {
            originalImageUrl = "$baseUrl/images/${data['image_path']}?t=$timestamp";
            annotatedImageUrl = "$baseUrl/images/${data['annotated_path']}?t=$timestamp";
            loading = false;
          });
        } else {
          setState(() {
            errorMessage = "Échec: ${data['message']}";
            loading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Erreur serveur: ${response.statusCode}";
          loading = false;
        });
      }
    } on SocketException {
      setState(() {
        errorMessage = "Erreur de réseau. Vérifiez la connexion.";
        loading = false;
      });
    } on http.ClientException {
      setState(() {
        errorMessage = "Impossible de se connecter au serveur.";
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Erreur: $e";
        loading = false;
      });
    }
  }

  void refreshPage() {
    setState(() {
      originalImageUrl = null;
      annotatedImageUrl = null;
      errorMessage = null;
    });
    _checkServerStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Test d'affichage des images"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshPage,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status du serveur
            Card(
              color: serverStatus == 'Connecté' ? Colors.green[100] : Colors.orange[100],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(
                      serverStatus == 'Connecté' ? Icons.check_circle : Icons.warning,
                      color: serverStatus == 'Connecté' ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Status: $serverStatus",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: serverStatus == 'Connecté' ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (serverStatus != 'Connecté')
                      Text(
                        baseUrl,
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Boutons
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: serverStatus == 'Connecté' ? captureImage : null,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Capturer une image"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: refreshPage,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Rafraîchir"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Chargement
            if (loading) const Center(child: CircularProgressIndicator()),

            // Message d'erreur
            if (errorMessage != null)
              Card(
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Images
            if (originalImageUrl != null && annotatedImageUrl != null)
              Expanded(
                child: ListView(
                  children: [
                    _buildImageCard("Image originale", originalImageUrl!),
                    _buildImageCard("Image avec polygone", annotatedImageUrl!),
                  ],
                ),
              )
            else if (!loading && serverStatus == 'Connecté')
              const Center(
                child: Text("Cliquez sur 'Capturer une image' pour démarrer"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String title, String imageUrl) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Image.network(
            imageUrl,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 40),
                    SizedBox(height: 8),
                    Text("Erreur de chargement de l'image"),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}