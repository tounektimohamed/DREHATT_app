import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ImageComparisonPage extends StatefulWidget {
  const ImageComparisonPage({super.key});

  @override
  _ImageComparisonPageState createState() => _ImageComparisonPageState();
}

class _ImageComparisonPageState extends State<ImageComparisonPage> {
  String statusMessage = 'En attente...';
  String connectedUrl = '';
  Uint8List? img1;
  Uint8List? img2;
  Uint8List? diffImg;
  double changeRatio = 0.0;
  bool isLoading = false;

  List<String> availableDates = [];
  String? selectedDate1;
  String? selectedDate2;

  final List<String> serverUrls = [
    "http://10.0.2.2:5000", // Android Emulator
    "http://localhost:5000", // iOS Simulator
    "http://192.168.1.100:5000", // Exemple IP réseau local
  ];

  Future<void> checkConnection() async {
    setState(() {
      statusMessage = 'Connexion en cours...';
      connectedUrl = '';
      isLoading = true;
    });

    for (String url in serverUrls) {
      try {
        final response = await http.get(Uri.parse('$url/ping')).timeout(const Duration(seconds: 3));
        if (response.statusCode == 200 && response.body == "pong") {
          setState(() {
            statusMessage = '✅ Connecté au serveur : $url';
            connectedUrl = url;
            isLoading = false;
          });
          fetchAvailableDates();
          return;
        }
      } catch (_) {
        continue; // Essayer l'URL suivante
      }
    }

    setState(() {
      statusMessage = '❌ Impossible de se connecter au serveur.';
      isLoading = false;
    });
  }

  Future<void> fetchAvailableDates() async {
    if (connectedUrl.isEmpty) return;

    try {
      final response = await http.get(Uri.parse('$connectedUrl/list_dates'));
      if (response.statusCode == 200) {
        List<dynamic> dates = jsonDecode(response.body);
        setState(() {
          availableDates = dates.map((d) => d.toString()).toList();
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = 'Erreur lors du chargement des dates';
      });
    }
  }

  Future<void> compareImages() async {
    if (connectedUrl.isEmpty) {
      setState(() {
        statusMessage = "⚠️ Non connecté au serveur.";
      });
      return;
    }

    if (selectedDate1 == null || selectedDate2 == null) {
      setState(() {
        statusMessage = "⚠️ Veuillez sélectionner deux dates.";
      });
      return;
    }

    // Vérification des dates dans la liste disponible
    if (!availableDates.contains(selectedDate1) || !availableDates.contains(selectedDate2)) {
      setState(() {
        statusMessage = "⚠️ Les dates choisies ne sont pas disponibles.";
      });
      return;
    }

    setState(() {
      statusMessage = "Comparaison en cours...";
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$connectedUrl/compare'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'date1': selectedDate1,
          'date2': selectedDate2,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          img1 = base64Decode(data['img1']);
          img2 = base64Decode(data['img2']);
          diffImg = base64Decode(data['diff_img']);
          changeRatio = data['change_ratio'].toDouble();
          statusMessage = changeRatio == 0.0
              ? "✅ Aucun changement détecté."
              : "✅ Comparaison terminée.";
        });
      } else {
        setState(() {
          statusMessage = "❌ Erreur côté serveur (${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = "❌ Erreur: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void setTodayVsYesterday() {
    if (availableDates.length >= 2) {
      setState(() {
        selectedDate1 = availableDates[availableDates.length - 2];
        selectedDate2 = availableDates[availableDates.length - 1];
      });
    } else {
      setState(() {
        statusMessage = "⚠️ Pas assez de dates disponibles.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comparaison d\'images')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(statusMessage, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: checkConnection,
              child: const Text("Vérifier la connexion"),
            ),
            const SizedBox(height: 20),

            if (availableDates.isNotEmpty) ...[
              DropdownButton<String>(
                hint: const Text("Sélectionner la première date"),
                value: selectedDate1,
                onChanged: (value) => setState(() => selectedDate1 = value),
                items: availableDates.map((date) => DropdownMenuItem(value: date, child: Text(date))).toList(),
              ),
              DropdownButton<String>(
                hint: const Text("Sélectionner la deuxième date"),
                value: selectedDate2,
                onChanged: (value) => setState(() => selectedDate2 = value),
                items: availableDates.map((date) => DropdownMenuItem(value: date, child: Text(date))).toList(),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: setTodayVsYesterday,
                child: const Text("Aujourd'hui vs Hier"),
              ),
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: compareImages,
              child: const Text("Comparer les images"),
            ),
            const SizedBox(height: 20),

            if (isLoading) const CircularProgressIndicator(),
            if (img1 != null && img2 != null && diffImg != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: Column(children: [const Text("Image 1"), Image.memory(img1!, height: 150)])),
                  Expanded(child: Column(children: [const Text("Image 2"), Image.memory(img2!, height: 150)])),
                  Expanded(child: Column(children: [const Text("Différence"), Image.memory(diffImg!, height: 150)])),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                changeRatio == 0.0
                    ? "Aucun changement détecté"
                    : "Changement détecté : ${(changeRatio * 100).toStringAsFixed(2)}%",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
