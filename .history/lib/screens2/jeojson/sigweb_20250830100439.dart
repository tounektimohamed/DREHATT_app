import 'dart:convert';
import 'dart:typed_data';
import 'package:DREHATT_app/screens2/jeojson/convertGeoJson.dart';
import 'package:DREHATT_app/screens2/jeojson/gerehtml.dart';
import 'package:DREHATT_app/screens2/jeojson/localhtml.dart';
import 'package:DREHATT_app/screens2/kml/KmlMapPage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class SigWeb extends StatefulWidget {
  const SigWeb({super.key, required this.title});

  final String title;

  @override
  State<SigWeb> createState() => _SigWebState();
}

class _SigWebState extends State<SigWeb> {
  bool loadingData = false;
  bool uploadingData = false;
  double uploadProgress = 0.0;
  GoogleMapController? mapController;
  String _selectedGeoJsonDocumentId = '';
  Set<Polygon> polygons = {};
  MapType _currentMapType = MapType.normal;
  Set<Polyline> polylines = {};

  final Map<String, Color> layerColorMap = {
    'EQUIP': Color(0xff0e38c0),
    '1 UAa1': Color(0xffdb7979),
    '1 E': Colors.red,
    '1 UAa4': Color(0xff4caf50),
    '1 UVa': Color(0xff2196f3),
    '1 NAa': Color(0xffff9800),
    '1 UVb': Color(0xff9c27b0),
    '1 UBa': Color(0xffe91e63),
    '0 fonts': Color(0xff93C572),
  };

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGeoJsonSelectionDialog();
    });
  }

  LatLngBounds calculateBoundingBox(List<LatLng> points) {
    double? minLat, maxLat, minLon, maxLon;

    for (var point in points) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLon == null || point.longitude < minLon) minLon = point.longitude;
      if (maxLon == null || point.longitude > maxLon) maxLon = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat ?? 0, minLon ?? 0),
      northeast: LatLng(maxLat ?? 0, maxLon ?? 0),
    );
  }

  Future<void> uploadGeoJsonToStorage(
      String fileName, Uint8List fileBytes) async {
    try {
      final storageRef =
          FirebaseStorage.instance.ref().child('geojson_files/$fileName');
      await storageRef.putData(fileBytes);
      final downloadUrl = await storageRef.getDownloadURL();

      print('GeoJSON uploaded to Storage successfully: $downloadUrl');
    } catch (e) {
      print('Error uploading GeoJSON: $e');
    }
  }

  Future<void> loadGeoJsonFromStorage(String fileName) async {
    if (mapController == null) {
      print('Map controller is not initialized');
      return;
    }

    try {
      setState(() {
        loadingData = true;
      });

      final storageRef =
          FirebaseStorage.instance.ref().child('geojson_files/$fileName');
      final downloadUrl = await storageRef.getDownloadURL();
      final response = await http.get(Uri.parse(downloadUrl));
      final geoJsonData = response.body;

      final decodedGeoJson = json.decode(geoJsonData);
      final Set<Polygon> newPolygons = {};
      final Set<Polyline> newPolylines = {};

      int index = 0;
      for (var feature in decodedGeoJson['features']) {
        if (feature['geometry']['type'] == 'MultiPolygon') {
          final List<List<LatLng>> polygonList = [];
          for (var polygon in feature['geometry']['coordinates']) {
            final List<LatLng> ringPoints = [];
            for (var ring in polygon) {
              for (var coord in ring) {
                ringPoints.add(LatLng(coord[1], coord[0]));
              }
            }
            polygonList.add(ringPoints);
          }

          final polygonId = PolygonId('polygon_$index');
          index++;

          final String? fillHex = feature['properties']['fill'];
          final double fillOpacity =
              feature['properties']['fill-opacity']?.toDouble() ?? 0.5;
          final Color fillColor = fillHex != null
              ? Color(int.parse(fillHex.replaceFirst('#', '0xFF')))
              : Color.fromARGB(0, 236, 125, 125);

          newPolygons.add(
            Polygon(
              polygonId: polygonId,
              points: polygonList.expand((ring) => ring).toList(),
              strokeColor: feature['properties']['stroke'] != null
                  ? Color(int.parse(feature['properties']['stroke']
                      .replaceFirst('#', '0xFF')))
                  : Colors.black,
              strokeWidth:
                  feature['properties']['stroke-width']?.toDouble() ?? 2.0,
              fillColor: fillColor.withOpacity(fillOpacity),
              onTap: () {
                _showPolygonInfo(feature['properties']);
              },
            ),
          );
        } else if (feature['geometry']['type'] == 'LineString') {
          final List<LatLng> linePoints = [];
          for (var coord in feature['geometry']['coordinates']) {
            if (coord is List && coord.length >= 2) {
              linePoints.add(LatLng(coord[1], coord[0]));
            }
          }

          final polylineId = PolylineId('polyline_$index');
          index++;

          newPolylines.add(
            Polyline(
              polylineId: polylineId,
              points: linePoints,
              color: Colors.red,
              width: 3,
            ),
          );
        } else if (feature['geometry']['type'] == 'MultiLineString') {
          for (var line in feature['geometry']['coordinates']) {
            final List<LatLng> linePoints = [];
            for (var coord in line) {
              if (coord is List && coord.length >= 2) {
                linePoints.add(LatLng(coord[1], coord[0]));
              }
            }

            final polylineId = PolylineId('polyline_$index');
            index++;

            newPolylines.add(
              Polyline(
                polylineId: polylineId,
                points: linePoints,
                color: Color.fromARGB(255, 255, 179, 66),
                width: 3,
              ),
            );
          }
        }
      }

      setState(() {
        polygons = newPolygons;
        polylines = newPolylines;
      });

      if (newPolygons.isNotEmpty || newPolylines.isNotEmpty) {
        final allPoints =
            newPolygons.expand((polygon) => polygon.points).toList();
        allPoints.addAll(newPolylines.expand((polyline) => polyline.points));
        final bounds = calculateBoundingBox(allPoints);
        mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }

      print('GeoJSON loaded and parsed successfully');
    } catch (e) {
      print('Error loading GeoJSON: $e');
    } finally {
      setState(() {
        loadingData = false;
      });
    }
  }

  Future<void> uploadGeoJsonToFirestore(
      String documentId, String geoJsonData) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('geojson_files').doc(documentId).set({
        'geojson': geoJsonData,
      });
      print('GeoJSON uploaded successfully');
    } catch (e) {
      print('Error uploading GeoJSON: $e');
    }
  }

  Future<void> _deleteGeoJsonFile(String fileName) async {
    try {
      final storageRef =
          FirebaseStorage.instance.ref().child('geojson_files/$fileName');
      await storageRef.delete();
      print('File deleted successfully');
      _showGeoJsonSelectionDialog();
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  Future<void> _confirmAndDeleteGeoJsonFile(String fileName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer ce fichier ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final storageRef =
            FirebaseStorage.instance.ref().child('geojson_files/$fileName');
        await storageRef.delete();
        print('File deleted successfully');
        _showGeoJsonSelectionDialog();
      } catch (e) {
        print('Error deleting file: $e');
      }
    }
  }

  Future<void> _showGeoJsonSelectionDialog() async {
    try {
      final storage = FirebaseStorage.instance;
      final listResult = await storage.ref('geojson_files').listAll();
      print('Files in Storage: ${listResult.items.length}');

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: 500, maxHeight: 500),
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sélectionner un fichier GeoJSON',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: listResult.items.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun fichier GeoJSON disponible',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: listResult.items.length,
                            itemBuilder: (context, index) {
                              final fileRef = listResult.items[index];
                              final fileName = fileRef.name;

                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 4.0),
                                child: ListTile(
                                  leading: Icon(Icons.map, color: Colors.blue),
                                  title: Text(
                                    fileName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red, size: 20),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          _confirmAndDeleteGeoJsonFile(
                                              fileName);
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _selectGeoJson(fileName);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Fermer'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('Error listing GeoJSON files: $e');
      if (e is FirebaseException) {
        print('Error Code: ${e.code}');
        print('Error Message: ${e.message}');
      }
    }
  }

  Future<void> _selectGeoJson(String fileName) async {
    try {
      await loadGeoJsonFromStorage(fileName);
    } catch (e) {
      print('Error selecting GeoJSON file: $e');
    }
  }

  Future<void> _uploadGeoJsonFile() async {
    try {
      setState(() {
        uploadingData = true;
        uploadProgress = 0.0;
      });

      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['geojson']);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        final Uint8List fileBytes = file.bytes!;
        final String fileName = file.name;

        final storageRef =
            FirebaseStorage.instance.ref().child('geojson_files/$fileName');
        final uploadTask = storageRef.putData(fileBytes);

        uploadTask.snapshotEvents.listen((taskSnapshot) {
          setState(() {
            uploadProgress =
                (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
          });
        });

        await uploadTask.whenComplete(() async {
          final downloadUrl = await storageRef.getDownloadURL();
          print('File uploaded successfully: $downloadUrl');
          setState(() {
            uploadingData = false;
          });
        }).catchError((error) {
          print('Error uploading file: $error');
          setState(() {
            uploadingData = false;
          });
        });
      }
    } catch (e) {
      print('Error picking file: $e');
      setState(() {
        uploadingData = false;
      });
    }
  }

  void _changeMapType(MapType mapType) {
    setState(() {
      _currentMapType = mapType;
    });
  }

  void _showMapTypeSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sélectionner le type de carte',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                _buildMapTypeOption('Normal', MapType.normal, Icons.map),
                _buildMapTypeOption('Satellite', MapType.satellite, Icons.satellite),
                _buildMapTypeOption('Terrain', MapType.terrain, Icons.terrain),
                _buildMapTypeOption('Hybride', MapType.hybrid, Icons.layers),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapTypeOption(String title, MapType mapType, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      onTap: () {
        _changeMapType(mapType);
        Navigator.of(context).pop();
      },
    );
  }

  void _showPolygonInfo(Map<String, dynamic> properties) {
    String layerName = properties['Layer'] ?? 'Couche inconnue';
    Color polygonColor = Colors.white;

    if (properties.containsKey('fill')) {
      String? fillHex = properties['fill'];
      if (fillHex != null) {
        polygonColor = Color(int.parse(fillHex.replaceFirst('#', '0xFF')));
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations du polygone',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: polygonColor,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(
                      layerName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: properties.entries.map((entry) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key}: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value.toString(),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Fermer'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Suivi des PAUS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          _buildAppBarAction(
            icon: Icons.web,
            tooltip: 'Afficher HTML Local',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HtmlListPage()),
              );
            },
          ),
          _buildAppBarAction(
            icon: Icons.web_asset,
            tooltip: 'Gérer les pages HTML',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HtmlPagesList()),
              );
            },
          ),
          _buildAppBarAction(
            icon: Icons.change_circle,
            tooltip: 'Convertisseur GeoJSON',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GeoJsonConverterPage()),
              );
            },
          ),
          _buildAppBarAction(
            icon: Icons.map_sharp,
            tooltip: 'Lecteur KML',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => KmlMapPage()),
              );
            },
          ),
          _buildAppBarAction(
            icon: Icons.cloud_upload,
            tooltip: 'Télécharger un fichier GeoJSON',
            onPressed: _uploadGeoJsonFile,
          ),
          _buildAppBarAction(
            icon: Icons.folder_open,
            tooltip: 'Liste des PAUS',
            onPressed: _showGeoJsonSelectionDialog,
          ),
          _buildAppBarAction(
            icon: Icons.layers,
            tooltip: 'Changer le type de carte',
            onPressed: _showMapTypeSelectionDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            polygons: polygons,
            polylines: polylines,
            mapType: _currentMapType,
            initialCameraPosition: CameraPosition(
              target: LatLng(32.9295, 10.4518),
              zoom: 12,
            ),
          ),
          if (loadingData)
            Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    SizedBox(height: 16),
                    Text(
                      'Chargement des données...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          if (uploadingData)
            Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        children: [
                          CircularProgressIndicator(
                            value: uploadProgress / 100,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            strokeWidth: 4,
                          ),
                          Center(
                            child: Text(
                              '${uploadProgress.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Téléchargement en cours...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _showGeoJsonSelectionDialog,
              child: Icon(Icons.layers),
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }
}