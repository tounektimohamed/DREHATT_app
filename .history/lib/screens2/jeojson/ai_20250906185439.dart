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
      home: const SatelliteMonitorPage(),
    );
  }
}

class SatelliteMonitorPage extends StatefulWidget {
  const SatelliteMonitorPage({super.key});

  @override
  State<SatelliteMonitorPage> createState() => _SatelliteMonitorPageState();
}

class _SatelliteMonitorPageState extends State<SatelliteMonitorPage> {
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
  double? aiChangePercentage;
  String? aiAnnotatedImageUrl;
  final List<String> baseUrls = [
    "http://10.0.2.2:5000",
    "http://localhost:5000",
    "http://192.168.1.100:5000",
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
        errorMessage = 'Impossible de se connecter au serveur Flask.';
      });
    }
  }

  Future<void> captureAndCompare() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/capture_and_compare"),
            headers: {"Content-Type": "application/x-www-form-urlencoded"},
            body:
                "lat=${selectedPosition.latitude}&lon=${selectedPosition.longitude}&zoom=$zoomLevel",
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["status"] == "success") {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          setState(() {
            originalImageUrl =
                "$baseUrl/images/${data['image_path']}?t=$timestamp";
            if (data['annotated_path'] != null) {
              annotatedImageUrl =
                  "$baseUrl/images/${data['annotated_path']}?t=$timestamp";
            }
            loading = false;
          });

          if (data['change_ratio'] != null) {
            final changeRatio = data['change_ratio'].toDouble();
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Résultat de la comparaison"),
                content: Text(
                    "Taux de différence: ${changeRatio.toStringAsFixed(2)}%"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
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
    } catch (e) {
      setState(() {
        errorMessage = "Erreur: $e";
        loading = false;
      });
    }
  }

  Future<void> resetComparison() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/reset_comparison"));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Comparaison réinitialisée")),
        );
        setState(() {
          changes = [];
          originalImageUrl = null;
          annotatedImageUrl = null;
        });
      }
    } catch (e) {
      print("Erreur réinitialisation: $e");
    }
  }

  Future<void> _getChanges() async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/get_changes")).timeout(
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
              color: serverStatus == 'Connecté'
                  ? Colors.green[100]
                  : Colors.orange[100],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(
                      serverStatus == 'Connecté'
                          ? Icons.check_circle
                          : Icons.warning,
                      color: serverStatus == 'Connecté'
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Status: $serverStatus",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: serverStatus == 'Connecté'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    if (serverStatus != 'Connecté') ...[
                      const SizedBox(width: 8),
                      Text(
                        baseUrl,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

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
                    Text(
                        "Latitude: ${selectedPosition.latitude.toStringAsFixed(6)}"),
                    Text(
                        "Longitude: ${selectedPosition.longitude.toStringAsFixed(6)}"),
                    Text("Niveau de zoom: $zoomLevel"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: toggleMapView,
                          icon: Icon(showMap ? Icons.close : Icons.map),
                          label: Text(
                              showMap ? "Masquer carte" : "Changer position"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                String lat =
                                    selectedPosition.latitude.toString();
                                String lon =
                                    selectedPosition.longitude.toString();
                                String zoom = zoomLevel.toString();

                                return AlertDialog(
                                  title: const Text(
                                      "Entrer les coordonnées manuellement"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        decoration: const InputDecoration(
                                            labelText: "Latitude"),
                                        controller:
                                            TextEditingController(text: lat),
                                        onChanged: (value) => lat = value,
                                      ),
                                      TextField(
                                        decoration: const InputDecoration(
                                            labelText: "Longitude"),
                                        controller:
                                            TextEditingController(text: lon),
                                        onChanged: (value) => lon = value,
                                      ),
                                      TextField(
                                        decoration: const InputDecoration(
                                            labelText: "Zoom"),
                                        controller:
                                            TextEditingController(text: zoom),
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
                                          updatePosition(
                                              LatLng(newLat, newLon));
                                          updateZoom(newZoom);
                                          Navigator.pop(context);
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    "Coordonnées invalides")),
                                          );
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

            if (showMap)
              Card(
                child: SizedBox(
                  height: 300,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: selectedPosition,
                      initialZoom: zoomLevel.toDouble(),
                      onTap: (tapPosition, point) {
                        updatePosition(point);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selectedPosition,
                            child: const Icon(
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
                  onPressed:
                      serverStatus == 'Connecté' ? captureAndCompare : null,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Capturer et comparer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: resetComparison,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text("Réinitialiser"),
                ),
                if (changes.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: toggleChangesView,
                    icon: Icon(
                        showChanges ? Icons.visibility_off : Icons.visibility),
                    label: Text(showChanges
                        ? "Masquer changements"
                        : "Afficher changements"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          showChanges ? Colors.orange : Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            if (loading) const Center(child: CircularProgressIndicator()),

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

            if (showChanges && changes.isNotEmpty) _buildChangesSection(),

            if (originalImageUrl != null)
              Expanded(
                child: ListView(
                  children: [
                    _buildImageCard("Image originale", originalImageUrl!),
                    if (annotatedImageUrl != null)
                      _buildImageCard(
                          "Image avec différences", annotatedImageUrl!),
                  ],
                ),
              )
            else if (!loading &&
                serverStatus == 'Connecté' &&
                !showChanges &&
                !showMap)
              const Center(
                child: Text("Cliquez sur 'Capturer et comparer' pour démarrer"),
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
                final changeRatio =
                    change['change_ratio']?.toStringAsFixed(2) ?? '0.00';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    leading:
                        const Icon(Icons.change_circle, color: Colors.blue),
                    title: Text("Changement: $changeRatio%"),
                    subtitle: Text(
                        "Date: ${DateTime.parse(timestamp).toLocal().toString()}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () {
                        final timestamp = DateTime.now().millisecondsSinceEpoch;
                        setState(() {
                          originalImageUrl =
                              "$baseUrl/images/${change['image_path']}?t=$timestamp";
                          if (change['annotated_path'] != null) {
                            annotatedImageUrl =
                                "$baseUrl/images/${change['annotated_path']}?t=$timestamp";
                          }
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
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
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
