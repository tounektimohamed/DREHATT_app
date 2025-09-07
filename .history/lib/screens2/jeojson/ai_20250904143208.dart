import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // URL de ton backend Flask
  final String baseUrl = "http://127.0.0.1:5000"; // 🔴 changer pour ton IP serveur si nécessaire

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
      );

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
    } catch (e) {
      setState(() {
        errorMessage = "Erreur de connexion: $e";
        loading = false;
      });
    }
  }

  void refreshPage() {
    setState(() {}); // force rebuild
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Test d'affichage des images"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: captureImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Capturer une image"),
                ),
                ElevatedButton(
                  onPressed: refreshPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Rafraîchir"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(),
            if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            if (originalImageUrl != null && annotatedImageUrl != null)
              Expanded(
                child: ListView(
                  children: [
                    Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Image originale:", style: TextStyle(fontSize: 18)),
                          ),
                          Image.network(originalImageUrl!),
                        ],
                      ),
                    ),
                    Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("Image avec polygone:", style: TextStyle(fontSize: 18)),
                          ),
                          Image.network(annotatedImageUrl!),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (!loading)
              const Text("Cliquez sur 'Capturer une image' pour démarrer"),
          ],
        ),
      ),
    );
  }
}
