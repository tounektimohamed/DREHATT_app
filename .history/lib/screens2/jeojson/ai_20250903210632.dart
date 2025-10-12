import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';


class GeoSurveillanceScreen extends StatefulWidget {
  @override
  _GeoSurveillanceScreenState createState() => _GeoSurveillanceScreenState();
}

class _GeoSurveillanceScreenState extends State<GeoSurveillanceScreen> {
  final String apiKey = "AIzaSyAg9n0lYVhZgqSBAyOzRipaTvGiv9R7OVM";
  double lat = 32.9297;
  double lon = 10.4518;
  int zoom = 17;
  String size = "640x640";
  int scale = 2;
  String status = "Prêt";
  double changePercentage = 0.0;
  String changeLocation = "";
  List<String> imagePaths = [];
  bool isMonitoring = false;
  Timer? monitoringTimer;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadImages();
  }

  @override
  void dispose() {
    monitoringTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await Permission.location.request();
    await Permission.storage.request();
  }

  Future<void> _loadImages() async {
    final directory = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${directory.path}/images');
    
    if (await imageDir.exists()) {
      setState(() {
        imagePaths = imageDir
            .listSync()
            .where((file) => file.path.endsWith('.png'))
            .map((file) => file.path)
            .toList();
      });
    }
  }

  Future<String> _fetchImage() async {
    setState(() => status = "Téléchargement de l'image...");
    
    final url = "https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lon&zoom=$zoom&size=$size&scale=$scale&maptype=satellite&key=$apiKey";
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final directory = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${directory.path}/images');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = '${imageDir.path}/map_$timestamp.png';
      final file = File(imagePath);
      await file.writeAsBytes(response.bodyBytes);
      
      setState(() {
        status = "Image sauvegardée: $imagePath";
        imagePaths.add(imagePath);
      });
      
      return imagePath;
    } else {
      throw Exception('Échec du téléchargement de l\'image');
    }
  }

  Future<void> _compareImages() async {
    if (imagePaths.length < 2) {
      setState(() => status = "Besoin d'au moins 2 images pour comparer");
      return;
    }
    
    setState(() => status = "Comparaison des images...");
    
    final String imagePath1 = imagePaths[imagePaths.length - 2];
    final String imagePath2 = imagePaths[imagePaths.length - 1];
    
    try {
      // Charger les images
      final File file1 = File(imagePath1);
      final File file2 = File(imagePath2);
      final bytes1 = await file1.readAsBytes();
      final bytes2 = await file2.readAsBytes();
      
      final img.Image image1 = img.decodeImage(bytes1)!;
      final img.Image image2 = img.decodeImage(bytes2)!;
      
      // Définir la zone de polygone (coordonnées normalisées)
      final List<Offset> polygonPoints = [
        Offset(0.3, 0.3),
        Offset(0.7, 0.3),
        Offset(0.7, 0.7),
        Offset(0.3, 0.7),
      ];
      
      // Convertir en coordonnées pixels
      final List<ui.Offset> pixelPolygon = polygonPoints.map((point) {
        return ui.Offset(
          point.dx * image1.width,
          point.dy * image1.height,
        );
      }).toList();
      
      // Créer un masque pour la zone d'intérêt
      final mask = _createPolygonMask(image1.width, image1.height, pixelPolygon);
      
      // Calculer les différences
      int diffPixels = 0;
      int totalPixels = 0;
      
      for (int y = 0; y < image1.height; y++) {
        for (int x = 0; x < image1.width; x++) {
          if (mask[y][x] > 0) {
            totalPixels++;
            
            // Obtenir les couleurs des pixels (méthode corrigée)
            final pixel1 = image1.getPixel(x, y);
            final pixel2 = image2.getPixel(x, y);
            
            // Extraire les composantes RVB correctement
            final r1 = img.getRed(pixel1);
            final g1 = img.getGreen(pixel1);
            final b1 = img.getBlue(pixel1);
            
            final r2 = img.getRed(pixel2);
            final g2 = img.getGreen(pixel2);
            final b2 = img.getBlue(pixel2);
            
            final rDiff = (r1 - r2).abs();
            final gDiff = (g1 - g2).abs();
            final bDiff = (b1 - b2).abs();
            
            if (rDiff > 30 || gDiff > 30 || bDiff > 30) {
              diffPixels++;
            }
          }
        }
      }
      
      final double changeRatio = totalPixels > 0 ? (diffPixels / totalPixels) * 100 : 0;
      
      setState(() {
        changePercentage = changeRatio;
        
        if (changeRatio > 10) {
          status = "⚠️ Changement important détecté!";
          changeLocation = "Centre approximatif: ${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}";
        } else if (changeRatio > 2) {
          status = "ℹ️ Changements mineurs détectés";
          changeLocation = "Centre approximatif: ${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}";
        } else {
          status = "✅ Aucun changement significatif";
          changeLocation = "";
        }
      });
      
    } catch (e) {
      setState(() => status = "Erreur lors de la comparaison: $e");
    }
  }

  List<List<int>> _createPolygonMask(int width, int height, List<ui.Offset> polygon) {
    final mask = List.generate(height, (_) => List.filled(width, 0));
    
    // Pour cette démo, nous utilisons un rectangle simple défini par les points min/max
    final int minX = polygon.map((p) => p.dx.toInt()).reduce(min);
    final int maxX = polygon.map((p) => p.dx.toInt()).reduce(max);
    final int minY = polygon.map((p) => p.dy.toInt()).reduce(min);
    final int maxY = polygon.map((p) => p.dy.toInt()).reduce(max);
    
    for (int y = minY; y < maxY; y++) {
      for (int x = minX; x < maxX; x++) {
        if (y >= 0 && y < height && x >= 0 && x < width) {
          mask[y][x] = 1;
        }
      }
    }
    
    return mask;
  }

  void _startMonitoring() {
    setState(() {
      isMonitoring = true;
      status = "Surveillance démarrée";
    });
    
    monitoringTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
      await _fetchImage();
      if (imagePaths.length >= 2) {
        await _compareImages();
      }
    });
  }

  void _stopMonitoring() {
    monitoringTimer?.cancel();
    setState(() {
      isMonitoring = false;
      status = "Surveillance arrêtée";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Surveillance Géographique'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadImages,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Affichage du statut
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Statut: $status', style: TextStyle(fontSize: 16)),
                    if (changePercentage > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Changement: ${changePercentage.toStringAsFixed(2)}%',
                            style: TextStyle(
                                fontSize: 16,
                                color: changePercentage > 10
                                    ? Colors.red
                                    : changePercentage > 2
                                        ? Colors.orange
                                        : Colors.green)),
                      ),
                    if (changeLocation.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(changeLocation, style: TextStyle(fontSize: 14)),
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Boutons de contrôle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _fetchImage,
                  child: Text('Capturer'),
                ),
                ElevatedButton(
                  onPressed: imagePaths.length >= 2 ? _compareImages : null,
                  child: Text('Comparer'),
                ),
                ElevatedButton(
                  onPressed: isMonitoring ? _stopMonitoring : _startMonitoring,
                  child: Text(isMonitoring ? 'Arrêter' : 'Surveiller'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMonitoring ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Images capturées
            Expanded(
              child: imagePaths.isEmpty
                  ? Center(child: Text('Aucune image capturée'))
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: imagePaths.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Image.file(File(imagePaths[index]), fit: BoxFit.cover),
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                color: Colors.black54,
                                child: Text(
                                  'Image ${index + 1}',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}