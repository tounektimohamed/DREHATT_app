import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';


class GeoSurveillanceAIScreen extends StatefulWidget {
  @override
  _GeoSurveillanceAIScreenState createState() => _GeoSurveillanceAIScreenState();
}

class _GeoSurveillanceAIScreenState extends State<GeoSurveillanceAIScreen> {
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
  bool isAiEnabled = true;
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
      
      // Calculer les différences avec IA
      final changeResult = isAiEnabled 
          ? _compareWithAI(image1, image2, mask)
          : _compareBasic(image1, image2, mask);
      
      setState(() {
        changePercentage = changeResult.changeRatio;
        
        if (changeResult.changeRatio > 10) {
          status = "⚠️ Changement important détecté!";
          changeLocation = "Centre approximatif: ${changeResult.centerLat.toStringAsFixed(6)}, ${changeResult.centerLon.toStringAsFixed(6)}";
        } else if (changeResult.changeRatio > 2) {
          status = "ℹ️ Changements mineurs détectés";
          changeLocation = "Centre approximatif: ${changeResult.centerLat.toStringAsFixed(6)}, ${changeResult.centerLon.toStringAsFixed(6)}";
        } else {
          status = "✅ Aucun changement significatif";
          changeLocation = "";
        }
      });
      
    } catch (e) {
      setState(() => status = "Erreur lors de la comparaison: $e");
    }
  }

  // Méthode de comparaison avec algorithme IA amélioré
  ChangeResult _compareWithAI(img.Image image1, img.Image image2, List<List<int>> mask) {
    int diffPixels = 0;
    int totalPixels = 0;
    double totalX = 0;
    double totalY = 0;
    
    // Prétraitement des images
    final processed1 = _preprocessImage(image1);
    final processed2 = _preprocessImage(image2);
    
    for (int y = 0; y < image1.height; y++) {
      for (int x = 0; x < image1.width; x++) {
        if (mask[y][x] > 0) {
          totalPixels++;
          
          final pixel1 = processed1.getPixel(x, y);
          final pixel2 = processed2.getPixel(x, y);
          
          // Extraire les composantes RVB
          final r1 = img.getRed(pixel1);
          final g1 = img.getGreen(pixel1);
          final b1 = img.getBlue(pixel1);
          
          final r2 = img.getRed(pixel2);
          final g2 = img.getGreen(pixel2);
          final b2 = img.getBlue(pixel2);
          
          // Calcul de la différence avec pondération
          final diff = _calculateWeightedDifference(r1, g1, b1, r2, g2, b2);
          
          if (diff > 35) { // Seuil ajusté pour l'IA
            diffPixels++;
            totalX += x;
            totalY += y;
          }
        }
      }
    }
    
    final double changeRatio = totalPixels > 0 ? (diffPixels / totalPixels) * 100 : 0;
    
    // Calcul du centre des changements
    double centerLat = lat;
    double centerLon = lon;
    if (diffPixels > 0) {
      final centerX = totalX / diffPixels;
      final centerY = totalY / diffPixels;
      final centerCoords = _pixelToLatLon(centerX, centerY, image1.width, image1.height);
      centerLat = centerCoords.latitude;
      centerLon = centerCoords.longitude;
    }
    
    return ChangeResult(changeRatio, centerLat, centerLon);
  }

  // Prétraitement d'image pour l'IA
  img.Image _preprocessImage(img.Image image) {
    // Conversion en niveaux de gris
    final grayscale = img.grayscale(img.copyResize(image, width: image.width, height: image.height));
    
    // Application d'un filtre pour réduire le bruit
    return img.gaussianBlur(grayscale, 1);
  }

  // Calcul de différence pondérée (algorithme IA simplifié)
  double _calculateWeightedDifference(int r1, int g1, int b1, int r2, int g2, int b2) {
    // Conversion en espace colorimétrique Lab approximatif pour une meilleure détection
    final lab1 = _rgbToLab(r1, g1, b1);
    final lab2 = _rgbToLab(r2, g2, b2);
    
    // Distance Euclidienne dans l'espace Lab
    return sqrt(
      pow(lab2.l - lab1.l, 2) +
      pow(lab2.a - lab1.a, 2) +
      pow(lab2.b - lab1.b, 2)
    );
  }

  // Conversion RGB vers Lab (approximation)
  LabColor _rgbToLab(int r, int g, int b) {
    // Conversion RGB vers XYZ
    double rr = r / 255.0;
    double gg = g / 255.0;
    double bb = b / 255.0;
    
    rr = rr > 0.04045 ? pow((rr + 0.055) / 1.055, 2.4) : rr / 12.92;
    gg = gg > 0.04045 ? pow((gg + 0.055) / 1.055, 2.4) : gg / 12.92;
    bb = bb > 0.04045 ? pow((bb + 0.055) / 1.055, 2.4) : bb / 12.92;
    
    rr *= 100;
    gg *= 100;
    bb *= 100;
    
    double x = rr * 0.4124 + gg * 0.3576 + bb * 0.1805;
    double y = rr * 0.2126 + gg * 0.7152 + bb * 0.0722;
    double z = rr * 0.0193 + gg * 0.1192 + bb * 0.9505;
    
    // Conversion XYZ vers Lab
    x /= 95.047;
    y /= 100.0;
    z /= 108.883;
    
    x = x > 0.008856 ? pow(x, 1/3) : (7.787 * x) + 16/116;
    y = y > 0.008856 ? pow(y, 1/3) : (7.787 * y) + 16/116;
    z = z > 0.008856 ? pow(z, 1/3) : (7.787 * z) + 16/116;
    
    return LabColor(
      (116 * y) - 16,
      500 * (x - y),
      200 * (y - z)
    );
  }

  // Méthode de comparaison basique
  ChangeResult _compareBasic(img.Image image1, img.Image image2, List<List<int>> mask) {
    int diffPixels = 0;
    int totalPixels = 0;
    double totalX = 0;
    double totalY = 0;
    
    for (int y = 0; y < image1.height; y++) {
      for (int x = 0; x < image1.width; x++) {
        if (mask[y][x] > 0) {
          totalPixels++;
          
          final pixel1 = image1.getPixel(x, y);
          final pixel2 = image2.getPixel(x, y);
          
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
            totalX += x;
            totalY += y;
          }
        }
      }
    }
    
    final double changeRatio = totalPixels > 0 ? (diffPixels / totalPixels) * 100 : 0;
    
    // Calcul du centre des changements
    double centerLat = lat;
    double centerLon = lon;
    if (diffPixels > 0) {
      final centerX = totalX / diffPixels;
      final centerY = totalY / diffPixels;
      final centerCoords = _pixelToLatLon(centerX, centerY, image1.width, image1.height);
      centerLat = centerCoords.latitude;
      centerLon = centerCoords.longitude;
    }
    
    return ChangeResult(changeRatio, centerLat, centerLon);
  }

  // Conversion pixel vers coordonnées géographiques
  LatLng _pixelToLatLon(double x, double y, int width, int height) {
    // Approximation simple - pour une vraie application, utilisez des formules de projection
    final dx = (x - width / 2) / (width / 2);
    final dy = (y - height / 2) / (height / 2);
    
    final factor = pow(2, zoom) / 100000;
    
    return LatLng(
      lat + dy * factor,
      lon + dx * factor
    );
  }

  List<List<int>> _createPolygonMask(int width, int height, List<ui.Offset> polygon) {
    final mask = List.generate(height, (_) => List.filled(width, 0));
    
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
        title: Text('Surveillance Géographique IA'),
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
                    Row(
                      children: [
                        Icon(
                          isAiEnabled ? Icons.psychology : Icons.psychology_outlined,
                          color: isAiEnabled ? Colors.blue : Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text('Mode IA: ${isAiEnabled ? "Activé" : "Désactivé"}'),
                        Switch(
                          value: isAiEnabled,
                          onChanged: (value) {
                            setState(() => isAiEnabled = value);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
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

// Classes d'aide
class ChangeResult {
  final double changeRatio;
  final double centerLat;
  final double centerLon;

  ChangeResult(this.changeRatio, this.centerLat, this.centerLon);
}

class LabColor {
  final double l;
  final double a;
  final double b;

  LabColor(this.l, this.a, this.b);
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}