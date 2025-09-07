import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Satellite Image Comparison',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ImageComparisonPage(),
    );
  }
}

class ImageComparisonPage extends StatefulWidget {
  const ImageComparisonPage({super.key});

  @override
  State<ImageComparisonPage> createState() => _ImageComparisonPageState();
}

class _ImageComparisonPageState extends State<ImageComparisonPage> {
  String? image1Url;
  String? image2Url;
  String? diffImageUrl;
  bool loading = false;
  String? errorMessage;
  String serverStatus = 'Non connecté';
  double changeRatio = 0.0;
  List<String> availableDates = [];
  String? selectedDate1;
  String? selectedDate2;
  DateTime selectedCustomDate = DateTime.now();

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
        _getAvailableDates();
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

  Future<void> _getAvailableDates() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/get_available_dates")).timeout(
        const Duration(seconds: 5),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          availableDates = List<String>.from(data['dates'] ?? []);
          if (availableDates.isNotEmpty) {
            selectedDate1 = availableDates.last;
            if (availableDates.length > 1) {
              selectedDate2 = availableDates[availableDates.length - 2];
            } else {
              selectedDate2 = availableDates.last;
            }
          }
        });
      }
    } catch (e) {
      print("Erreur lors du chargement des dates: $e");
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
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["status"] == "success") {
          // Recharger les dates disponibles
          _getAvailableDates();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Image capturée: ${data['date']}")),
          );
        } else {
          setState(() {
            errorMessage = "Échec: ${data['message']}";
          });
        }
      } else {
        setState(() {
          errorMessage = "Erreur serveur: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Erreur: $e";
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> compareImages() async {
    if (selectedDate1 == null || selectedDate2 == null) {
      setState(() {
        errorMessage = "Veuillez sélectionner deux dates";
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
      image1Url = null;
      image2Url = null;
      diffImageUrl = null;
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/compare_images"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: "date1=$selectedDate1&date2=$selectedDate2",
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["status"] == "success") {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          setState(() {
            changeRatio = double.parse(data['change_ratio'].toString());
            image1Url = "$baseUrl/images/${data['image1_path']}?t=$timestamp";
            image2Url = "$baseUrl/images/${data['image2_path']}?t=$timestamp";
            diffImageUrl = "$baseUrl/images/${data['diff_image_path']}?t=$timestamp";
          });
        } else {
          setState(() {
            errorMessage = "Échec: ${data['message']}";
          });
        }
      } else {
        setState(() {
          errorMessage = "Erreur serveur: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Erreur: $e";
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void refreshPage() {
    setState(() {
      image1Url = null;
      image2Url = null;
      diffImageUrl = null;
      errorMessage = null;
    });
    _checkServerStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comparaison d'images satellite"),
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
            _buildServerStatus(),

            const SizedBox(height: 20),

            // Sélection des dates
            _buildDateSelection(),

            const SizedBox(height: 20),

            // Boutons
            _buildActionButtons(),

            const SizedBox(height: 20),

            // Chargement
            if (loading) const Center(child: CircularProgressIndicator()),

            // Message d'erreur
            if (errorMessage != null) _buildErrorMessage(),

            // Résultat de la comparaison
            if (changeRatio > 0) _buildComparisonResult(),

            // Affichage des images
            if (image1Url != null && image2Url != null && diffImageUrl != null)
              Expanded(
                child: ListView(
                  children: [
                    _buildImageCard("Image du $selectedDate1", image1Url!),
                    _buildImageCard("Image du $selectedDate2", image2Url!),
                    _buildImageCard("Différences détectées", diffImageUrl!),
                  ],
                ),
              )
            else if (!loading && serverStatus == 'Connecté')
              const Center(
                child: Text("Sélectionnez deux dates et cliquez sur 'Comparer'"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerStatus() {
    return Card(
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
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sélection des dates:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDate1,
                    items: availableDates.map((date) {
                      return DropdownMenuItem(
                        value: date,
                        child: Text(date),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDate1 = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Date 1",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDate2,
                    items: availableDates.map((date) {
                      return DropdownMenuItem(
                        value: date,
                        child: Text(date),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDate2 = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Date 2",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Options rapides:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    final yesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
                    setState(() {
                      selectedDate1 = today;
                      selectedDate2 = yesterday;
                    });
                  },
                  child: const Text("Aujourd'hui vs Hier"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    final lastWeek = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 7)));
                    setState(() {
                      selectedDate1 = today;
                      selectedDate2 = lastWeek;
                    });
                  },
                  child: const Text("Aujourd'hui vs Semaine dernière"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (availableDates.length > 1) {
                      setState(() {
                        selectedDate1 = availableDates.last;
                        selectedDate2 = availableDates.first;
                      });
                    }
                  },
                  child: const Text("Plus récent vs Plus ancien"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: serverStatus == 'Connecté' ? captureImage : null,
          icon: const Icon(Icons.camera_alt),
          label: const Text("Capturer image actuelle"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: serverStatus == 'Connecté' ? compareImages : null,
          icon: const Icon(Icons.compare),
          label: const Text("Comparer les images"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: refreshPage,
          icon: const Icon(Icons.refresh),
          label: const Text("Actualiser"),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Card(
      color: Colors.red[100],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildComparisonResult() {
    return Card(
      color: changeRatio > 5 ? Colors.orange[100] : Colors.green[100],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text(
              "Résultat de la comparaison:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Taux de changement: ${changeRatio.toStringAsFixed(2)}%",
              style: TextStyle(
                fontSize: 16,
                color: changeRatio > 5 ? Colors.orange[800] : Colors.green[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              changeRatio > 5 
                ? "Changements significatifs détectés!" 
                : "Changements mineurs ou stabilité",
              style: TextStyle(
                color: changeRatio > 5 ? Colors.orange[800] : Colors.green[800],
              ),
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