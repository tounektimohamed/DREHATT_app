import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
  List<dynamic> changes = [];
  bool showChanges = false;
  LatLng selectedPosition = const LatLng(32.9297, 10.4518);
  int zoomLevel = 17;
  bool showMap = false;

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
        // Charger les changements dès que le serveur est connecté
        _getChanges();
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
        body: "lat=${selectedPosition.latitude}&lon=${selectedPosition.longitude}&zoom=$zoomLevel",
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
          // Recharger les changements après une nouvelle capture
          _getChanges();
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

  Future<void> _getChanges() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_changes")).timeout(
        const Duration(seconds: 5),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          changes = data['changes'] ?? [];
        });
      }
    } catch (e) {
      print("Erreur lors du chargement des changements: $e");
    }
  }

  void refreshPage() {
    setState(() {
      originalImageUrl = null;
      annotatedImageUrl = null;
      errorMessage = null;
      changes = [];
    });
    _checkServerStatus();
  }

  void toggleChangesView() {
    setState(() {
      showChanges = !showChanges;
    });
  }

  void toggleMapView() {
    setState(() {
      showMap = !showMap;
    });
  }

  void updatePosition(LatLng newPosition) {
    setState(() {
      selectedPosition = newPosition;
    });
  }

  void updateZoom(int newZoom) {
    setState(() {
      zoomLevel = newZoom;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Surveillance par satellite"),
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

            // Position sélectionnée
           // Position sélectionnée
Card(
  child: Padding(
    padding: const EdgeInsets.all(12.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Position sélectionnée:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text("Latitude: ${selectedPosition.latitude.toStringAsFixed(6)}"),
        Text("Longitude: ${selectedPosition.longitude.toStringAsFixed(6)}"),
        Text("Niveau de zoom: $zoomLevel"),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: toggleMapView,
              icon: Icon(showMap ? Icons.close : Icons.map), // Correction ici
              label: Text(showMap ? "Masquer carte" : "Changer position"),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    String lat = selectedPosition.latitude.toString();
                    String lon = selectedPosition.longitude.toString();
                    String zoom = zoomLevel.toString();
                    
                    return AlertDialog(
                      title: const Text("Entrer les coordonnées manuellement"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            decoration: const InputDecoration(labelText: "Latitude"),
                            controller: TextEditingController(text: lat),
                            onChanged: (value) => lat = value,
                          ),
                          TextField(
                            decoration: const InputDecoration(labelText: "Longitude"),
                            controller: TextEditingController(text: lon),
                            onChanged: (value) => lon = value,
                          ),
                          TextField(
                            decoration: const InputDecoration(labelText: "Zoom"),
                            controller: TextEditingController(text: zoom),
                            onChanged: (value) => zoom = value,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Annuler"),
                        ),
                        TextButton(
                          onPressed: () {
                            try {
                              final newLat = double.parse(lat);
                              final newLon = double.parse(lon);
                              final newZoom = int.parse(zoom);
                              updatePosition(LatLng(newLat, newLon));
                              updateZoom(newZoom);
                              Navigator.pop(context);
                            } catch (e) {
                              // Gérer l'erreur de parsing
                            }
                          },
                          child: const Text("OK"),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.edit_location),
              label: const Text("Modifier"),
            ),
          ],
        ),
      ],
    ),
  ),
),

            // Carte pour sélectionner la position
          // Carte pour sélectionner la position
if (showMap)
  Card(
    child: SizedBox(
      height: 300,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: selectedPosition, // Correction ici
          initialZoom: zoomLevel.toDouble(), // Correction ici
          onTap: (tapPosition, point) {
            updatePosition(point);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: selectedPosition,
                child: const Icon( // Correction ici
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
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
                if (changes.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: toggleChangesView,
                    icon: Icon(showChanges ? Icons.visibility_off : Icons.visibility),
                    label: Text(showChanges ? "Masquer changements" : "Afficher changements"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: showChanges ? Colors.orange : Colors.purple,
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

            // Affichage des changements
            if (showChanges && changes.isNotEmpty)
              _buildChangesSection(),

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
            else if (!loading && serverStatus == 'Connecté' && !showChanges && !showMap)
              const Center(
                child: Text("Cliquez sur 'Capturer une image' pour démarrer"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangesSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Changements détectés:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: changes.length,
              itemBuilder: (context, index) {
                final change = changes[index];
                final timestamp = change['timestamp'];
                final changeRatio = change['change_ratio']?.toStringAsFixed(2) ?? '0.00';
                final changeCenter = change['change_center'];
                final imagePath = change['image_path'];
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    leading: const Icon(Icons.change_circle, color: Colors.blue),
                    title: Text("Changement: $changeRatio%"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Date: ${DateTime.parse(timestamp).toLocal().toString()}"),
                        if (changeCenter != null)
                          Text("Position: ${changeCenter[0]?.toStringAsFixed(4)}, ${changeCenter[1]?.toStringAsFixed(4)}"),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () {
                        // Afficher l'image associée à ce changement
                        final timestamp = DateTime.now().millisecondsSinceEpoch;
                        setState(() {
                          annotatedImageUrl = "$baseUrl/images/${imagePath.replaceAll('.png', '_with_polygon.png')}?t=$timestamp";
                          originalImageUrl = "$baseUrl/images/$imagePath?t=$timestamp";
                          showChanges = false;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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