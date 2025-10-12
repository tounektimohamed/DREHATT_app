import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ShapeDetailsPage.dart';

enum DrawShape { polygon, circle, line }
enum MapLayer { normal, satellite, terrain, hybrid }

class MapDrawingPage extends StatefulWidget {
  @override
  _MapDrawingPageState createState() => _MapDrawingPageState();
}

class _MapDrawingPageState extends State<MapDrawingPage> {
  GoogleMapController? mapController;
  List<LatLng> shapePoints = [];
  Set<Polygon> polygons = {};
  Set<Polyline> polylines = {};
  Set<Circle> circles = {};
  Set<Marker> markers = {}; // Nouveau: pour les marqueurs GPS
  DrawShape selectedShape = DrawShape.polygon;
  MapLayer selectedLayer = MapLayer.normal;
  bool isDrawing = false;
  bool showSaveButton = false;
  String displayText = '';

  // Nouveau: Compteur pour les IDs des marqueurs
  int _markerIdCounter = 0;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _startDrawing() {
    setState(() {
      isDrawing = true;
      shapePoints.clear();
      polygons.clear();
      polylines.clear();
      circles.clear();
      markers.clear(); // Clear les marqueurs quand on commence à dessiner
      displayText = '';
      showSaveButton = false;
    });
  }

  void _stopDrawing() {
    setState(() {
      isDrawing = false;
      showSaveButton = true;
      _updateDisplayText();
    });
  }

  void _clearShapes() {
    setState(() {
      shapePoints.clear();
      polygons.clear();
      polylines.clear();
      circles.clear();
      markers.clear(); // Clear aussi les marqueurs
      displayText = '';
      isDrawing = false;
      showSaveButton = false;
    });
  }

  void _onTap(LatLng position) {
    if (isDrawing) {
      switch (selectedShape) {
        case DrawShape.polygon:
          _drawPolygon(position);
          break;
        case DrawShape.circle:
          _drawCircle(position);
          break;
        case DrawShape.line:
          _drawLine(position);
          break;
      }
    }
  }

  void _drawPolygon(LatLng position) {
    setState(() {
      shapePoints.add(position);
      polygons.clear();
      if (shapePoints.length >= 3) {
        polygons.add(Polygon(
          polygonId: PolygonId('polygon'),
          points: shapePoints,
          strokeWidth: 3,
          fillColor: Colors.blue.withOpacity(0.3),
          strokeColor: Colors.blue,
        ));
      }
      _updateDisplayText();
    });
  }

  void _drawCircle(LatLng position) {
    setState(() {
      if (shapePoints.isEmpty) {
        shapePoints.add(position);
      } else if (shapePoints.length == 1) {
        double radius = _calculateDistance(shapePoints[0], position);
        circles.clear();
        circles.add(Circle(
          circleId: CircleId('circle'),
          center: shapePoints[0],
          radius: radius,
          strokeWidth: 3,
          fillColor: Colors.green.withOpacity(0.3),
          strokeColor: Colors.green,
        ));
        _stopDrawing();
      }
      _updateDisplayText();
    });
  }

  void _drawLine(LatLng position) {
    setState(() {
      if (shapePoints.isEmpty) {
        shapePoints.add(position);
      } else if (shapePoints.length == 1) {
        shapePoints.add(position);
        polylines.clear();
        polylines.add(Polyline(
          polylineId: PolylineId('line'),
          points: shapePoints,
          color: Colors.red,
          width: 3,
        ));
        _stopDrawing();
      }
      _updateDisplayText();
    });
  }

  double _calculateDistance(LatLng start, LatLng end) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((end.latitude - start.latitude) * p) / 2 +
        c(start.latitude * p) *
            c(end.latitude * p) *
            (1 - c((end.longitude - start.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)) * 1000;
  }

  double _calculatePolygonArea(List<LatLng> points) {
    const double radiusOfEarth = 6371000;
    double area = 0;

    if (points.length < 3) return 0;

    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;

      double lat1 = points[i].latitude * pi / 180;
      double lon1 = points[i].longitude * pi / 180;
      double lat2 = points[j].latitude * pi / 180;
      double lon2 = points[j].longitude * pi / 180;

      area += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2));
    }

    area = area * radiusOfEarth * radiusOfEarth / 2.0;
    return area.abs();
  }

  double _calculateShapeArea() {
    if (selectedShape == DrawShape.polygon && shapePoints.length > 2) {
      return _calculatePolygonArea(shapePoints);
    } else if (selectedShape == DrawShape.circle && circles.isNotEmpty) {
      double radius = circles.first.radius;
      return pi * radius * radius;
    }
    return 0;
  }

  void _updateDisplayText() {
    if (selectedShape == DrawShape.polygon && shapePoints.length > 2) {
      double area = _calculatePolygonArea(shapePoints);
      displayText = 'Aire: ${area.toStringAsFixed(2)} m²\nPoints: ${shapePoints.length}';
    } else if (selectedShape == DrawShape.circle && circles.isNotEmpty) {
      double radius = circles.first.radius;
      double area = pi * radius * radius;
      displayText = 'Aire: ${area.toStringAsFixed(2)} m²\nRayon: ${radius.toStringAsFixed(2)} m';
    } else if (selectedShape == DrawShape.line && shapePoints.length == 2) {
      double distance = _calculateDistance(shapePoints[0], shapePoints[1]);
      displayText = 'Distance: ${distance.toStringAsFixed(2)} m';
    } else if (selectedShape == DrawShape.polygon && shapePoints.isNotEmpty) {
      displayText = 'Points: ${shapePoints.length}\nAjoutez au moins 3 points';
    }
    setState(() {});
  }

  void _changeMapLayer(MapLayer layer) {
    if (mapController != null) {
      setState(() {
        selectedLayer = layer;
      });
      mapController!.setMapStyle(_getMapStyle(layer));
    }
  }

  String _getMapStyle(MapLayer layer) {
    switch (layer) {
      case MapLayer.satellite:
        return '[]';
      case MapLayer.terrain:
        return '[{"featureType": "all","elementType": "geometry","stylers": [{"visibility": "simplified"}]}]';
      case MapLayer.hybrid:
        return '[]';
      case MapLayer.normal:
      default:
        return '[]';
    }
  }

  MapType _getGoogleMapType(MapLayer layer) {
    switch (layer) {
      case MapLayer.satellite:
        return MapType.satellite;
      case MapLayer.terrain:
        return MapType.terrain;
      case MapLayer.hybrid:
        return MapType.hybrid;
      case MapLayer.normal:
      default:
        return MapType.normal;
    }
  }

  void _fetchSavedShapes() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('shapes').get();

      if (snapshot.docs.isEmpty) {
        _showMessage('Aucune forme enregistrée.');
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            child: Container(
              constraints: BoxConstraints(maxWidth: 500, maxHeight: 500),
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Formes Enregistrées',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.docs.length,
                      itemBuilder: (context, index) {
                        var doc = snapshot.docs[index];
                        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                        
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4.0),
                          elevation: 2,
                          child: ListTile(
                            leading: Icon(Icons.location_on, color: Colors.blue),
                            title: Text(data['name'] ?? 'Sans nom', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Type: ${data['shapeType'] ?? 'Inconnu'}\nSurface: ${data['area']?.toStringAsFixed(2) ?? '0'} m²'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.gps_fixed, color: Colors.green),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _showShapeLocation(data, doc.id);
                                  },
                                  tooltip: 'Voir la localisation',
                                ),
                                IconButton(
                                  icon: Icon(Icons.visibility, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _displaySavedShape(data, doc.id);
                                  },
                                  tooltip: 'Afficher la forme',
                                ),
                              ],
                            ),
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
      _showMessage('Erreur lors de la récupération des formes: $e');
    }
  }

  // Nouvelle méthode: Afficher seulement le marqueur GPS
  void _showShapeLocation(Map<String, dynamic> shapeData, String docId) {
    setState(() {
      // Clear existing shapes but keep markers for context
      polygons.clear();
      polylines.clear();
      circles.clear();
      shapePoints.clear();
      markers.clear();

      String shapeType = shapeData['shapeType'] ?? 'polygon';
      List<dynamic> coordinates = shapeData['coordinates'] ?? [];
      LatLng? shapeCenter;

      switch (shapeType) {
        case 'polygon':
          if (coordinates.isNotEmpty) {
            List<LatLng> points = _convertCoordinates(coordinates);
            shapeCenter = _getCenterOfPolygon(points);
          }
          break;

        case 'circle':
          if (coordinates.isNotEmpty) {
            shapeCenter = LatLng(coordinates[0]['latitude'], coordinates[0]['longitude']);
          }
          break;

        case 'line':
          if (coordinates.isNotEmpty) {
            List<LatLng> points = _convertCoordinates(coordinates);
            shapeCenter = _getCenterOfLine(points);
          }
          break;
      }

      if (shapeCenter != null) {
        // Ajouter le marqueur GPS
        _addGpsMarker(shapeCenter, shapeData, docId);
        
        // Update display text
        displayText = 'Localisation: ${shapeData['name'] ?? 'Sans nom'}\nType: ${shapeType}\nSurface: ${shapeData['area']?.toStringAsFixed(2) ?? '0'} m²';
        
        // Move camera to the marker
        mapController!.animateCamera(CameraUpdate.newLatLngZoom(shapeCenter, 15.0));
      }
    });
  }

  // Nouvelle méthode: Ajouter un marqueur GPS
  void _addGpsMarker(LatLng position, Map<String, dynamic> shapeData, String docId) {
    final String markerIdVal = 'gps_marker_${_markerIdCounter++}';
    final MarkerId markerId = MarkerId(markerIdVal);

    final Marker marker = Marker(
      markerId: markerId,
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: InfoWindow(
        title: shapeData['name'] ?? 'Forme sans nom',
        snippet: 'Type: ${shapeData['shapeType']}\nSurface: ${shapeData['area']?.toStringAsFixed(2)} m²',
      ),
      onTap: () {
        setState(() {
          displayText = '${shapeData['name'] ?? 'Sans nom'}\nType: ${shapeData['shapeType']}\nSurface: ${shapeData['area']?.toStringAsFixed(2)} m²';
        });
      },
    );

    setState(() {
      markers.add(marker);
    });
  }

  // Méthode existante pour afficher la forme complète
  void _displaySavedShape(Map<String, dynamic> shapeData, String docId) {
    setState(() {
      // Clear existing shapes
      polygons.clear();
      polylines.clear();
      circles.clear();
      markers.clear();
      shapePoints.clear();

      String shapeType = shapeData['shapeType'] ?? 'polygon';
      List<dynamic> coordinates = shapeData['coordinates'] ?? [];

      switch (shapeType) {
        case 'polygon':
          if (coordinates.isNotEmpty) {
            List<LatLng> points = _convertCoordinates(coordinates);
            polygons.add(Polygon(
              polygonId: PolygonId('saved_polygon_$docId'),
              points: points,
              strokeWidth: 3,
              fillColor: Colors.blue.withOpacity(0.3),
              strokeColor: Colors.blue,
            ));
            shapePoints.addAll(points);
            
            // Ajouter aussi un marqueur au centre
            LatLng center = _getCenterOfPolygon(points);
            _addGpsMarker(center, shapeData, docId);
          }
          break;

        case 'circle':
          if (coordinates.length >= 2) {
            LatLng center = LatLng(coordinates[0]['latitude'], coordinates[0]['longitude']);
            double radius = coordinates[1]['radius'] ?? 0.0;
            circles.add(Circle(
              circleId: CircleId('saved_circle_$docId'),
              center: center,
              radius: radius,
              strokeWidth: 3,
              fillColor: Colors.green.withOpacity(0.3),
              strokeColor: Colors.green,
            ));
            shapePoints.add(center);
            
            // Ajouter un marqueur au centre
            _addGpsMarker(center, shapeData, docId);
          }
          break;

        case 'line':
          if (coordinates.length >= 2) {
            List<LatLng> points = _convertCoordinates(coordinates);
            polylines.add(Polyline(
              polylineId: PolylineId('saved_line_$docId'),
              points: points,
              color: Colors.red,
              width: 3,
            ));
            shapePoints.addAll(points);
            
            // Ajouter un marqueur au centre de la ligne
            LatLng center = _getCenterOfLine(points);
            _addGpsMarker(center, shapeData, docId);
          }
          break;
      }

      // Update display text
      displayText = 'Forme chargée: ${shapeData['name'] ?? 'Sans nom'}\nType: ${shapeData['shapeType']}\nSurface: ${shapeData['area']?.toStringAsFixed(2) ?? '0'} m²';
      
      // Move camera to show the shape
      if (shapePoints.isNotEmpty && mapController != null) {
        mapController!.animateCamera(CameraUpdate.newLatLngBounds(
          _getBounds(shapePoints),
          50.0,
        ));
      }
    });
  }

  // Nouvelle méthode: Calculer le centre d'un polygone
  LatLng _getCenterOfPolygon(List<LatLng> points) {
    double totalLat = 0;
    double totalLng = 0;
    
    for (LatLng point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }
    
    return LatLng(totalLat / points.length, totalLng / points.length);
  }

  // Nouvelle méthode: Calculer le centre d'une ligne
  LatLng _getCenterOfLine(List<LatLng> points) {
    if (points.isEmpty) return LatLng(0, 0);
    if (points.length == 1) return points[0];
    
    int midIndex = points.length ~/ 2;
    return points[midIndex];
  }

  List<LatLng> _convertCoordinates(List<dynamic> coordinates) {
    return coordinates.map((coord) {
      return LatLng(coord['latitude'], coord['longitude']);
    }).toList();
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    double? west, north, east, south;
    
    for (LatLng point in points) {
      west = west != null ? (point.longitude < west ? point.longitude : west) : point.longitude;
      east = east != null ? (point.longitude > east ? point.longitude : east) : point.longitude;
      south = south != null ? (point.latitude < south ? point.latitude : south) : point.latitude;
      north = north != null ? (point.latitude > north ? point.latitude : north) : point.latitude;
    }
    
    return LatLngBounds(
      southwest: LatLng(south ?? 0, west ?? 0),
      northeast: LatLng(north ?? 0, east ?? 0),
    );
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Information'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _confirmSave() {
    if ((selectedShape == DrawShape.polygon && shapePoints.length < 3) ||
        (selectedShape == DrawShape.circle && circles.isEmpty) ||
        (selectedShape == DrawShape.line && shapePoints.length < 2)) {
      _showMessage('Veuillez compléter la forme avant de sauvegarder.');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enregistrer la forme'),
          content: Text('Voulez-vous enregistrer cette forme ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSavePage();
              },
              child: Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _showSavePage() {
    List<Map<String, dynamic>> coordinates = [];

    switch (selectedShape) {
      case DrawShape.polygon:
        coordinates = shapePoints.map((point) => {
          'latitude': point.latitude,
          'longitude': point.longitude
        }).toList();
        break;
      case DrawShape.circle:
        if (circles.isNotEmpty) {
          Circle circle = circles.first;
          coordinates = [
            {'latitude': circle.center.latitude, 'longitude': circle.center.longitude},
            {'radius': circle.radius}
          ];
        }
        break;
      case DrawShape.line:
        coordinates = shapePoints.map((point) => {
          'latitude': point.latitude,
          'longitude': point.longitude
        }).toList();
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => ShapeDetailsPage(
          shapeType: selectedShape.toString().split('.').last,
          area: _calculateShapeArea(),
          coordinates: coordinates,
        ),
      ),
    ).then((value) {
      // Reset drawing after saving
      _clearShapes();
    });
  }

  void _undoLastPoint() {
    setState(() {
      if (shapePoints.isNotEmpty) {
        shapePoints.removeLast();
        _updateShape();
        if (shapePoints.isEmpty) {
          _stopDrawing();
        }
      }
    });
  }

  void _updateShape() {
    switch (selectedShape) {
      case DrawShape.polygon:
        polygons.clear();
        if (shapePoints.length >= 3) {
          polygons.add(Polygon(
            polygonId: PolygonId('polygon'),
            points: shapePoints,
            strokeWidth: 3,
            fillColor: Colors.blue.withOpacity(0.3),
            strokeColor: Colors.blue,
          ));
        }
        break;
      case DrawShape.circle:
        circles.clear();
        if (shapePoints.length == 1) {
          // Keep the center point for circle
        } else {
          shapePoints.clear();
        }
        break;
      case DrawShape.line:
        polylines.clear();
        if (shapePoints.length == 1) {
          // Keep the first point for line
        } else if (shapePoints.length == 2) {
          polylines.add(Polyline(
            polylineId: PolylineId('line'),
            points: shapePoints,
            color: Colors.red,
            width: 3,
          ));
        } else {
          shapePoints.clear();
        }
        break;
    }
    _updateDisplayText();
  }

  void _showLayerSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sélectionner le type de carte',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                _buildLayerOption('Normal', MapLayer.normal, Icons.map),
                _buildLayerOption('Satellite', MapLayer.satellite, Icons.satellite),
                _buildLayerOption('Terrain', MapLayer.terrain, Icons.terrain),
                _buildLayerOption('Hybride', MapLayer.hybrid, Icons.layers),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayerOption(String title, MapLayer layer, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      onTap: () {
        _changeMapLayer(layer);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Permis de Bâtir',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          _buildAppBarAction(
            icon: Icons.undo,
            tooltip: 'Annuler le dernier point',
            onPressed: shapePoints.isNotEmpty ? _undoLastPoint : null,
          ),
          _buildAppBarAction(
            icon: Icons.delete,
            tooltip: 'Supprimer la forme',
            onPressed: polygons.isNotEmpty || polylines.isNotEmpty || circles.isNotEmpty || markers.isNotEmpty ? _clearShapes : null,
          ),
          _buildAppBarAction(
            icon: Icons.save,
            tooltip: 'Enregistrer la forme',
            onPressed: showSaveButton ? _confirmSave : null,
          ),
          _buildAppBarAction(
            icon: Icons.download,
            tooltip: 'Charger les formes enregistrées',
            onPressed: _fetchSavedShapes,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(33.1031, 10.4397),
              zoom: 9.0,
            ),
            polygons: polygons,
            polylines: polylines,
            circles: circles,
            markers: markers, // Ajout des marqueurs à la carte
            onTap: _onTap,
            mapType: _getGoogleMapType(selectedLayer),
          ),
          if (displayText.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Text(
                  displayText,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                ),
              ),
            ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusIndicator(),
                  SizedBox(height: 8),
                  Text(isDrawing ? 'Dessin en cours' : 'Prêt à dessiner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, -2))]),
        child: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.crop_square), label: 'Polygone'),
            BottomNavigationBarItem(icon: Icon(Icons.circle), label: 'Cercle'),
            BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Ligne'),
            BottomNavigationBarItem(icon: Icon(Icons.layers), label: 'Couche'),
          ],
          currentIndex: DrawShape.values.indexOf(selectedShape),
          onTap: (index) {
            if (index < DrawShape.values.length) {
              setState(() {
                selectedShape = DrawShape.values[index];
                _startDrawing();
              });
            } else {
              _showLayerSelectionDialog();
            }
          },
          backgroundColor: Colors.white,
          unselectedItemColor: Colors.grey[600],
          selectedItemColor: Colors.blue[800],
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
        ),
      ),
      floatingActionButton: isDrawing
          ? FloatingActionButton(
              onPressed: _stopDrawing,
              child: Icon(Icons.check, size: 28),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 4,
            )
          : FloatingActionButton(
              onPressed: _startDrawing,
              child: Icon(Icons.edit, size: 28),
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
              elevation: 4,
            ),
    );
  }

  Widget _buildAppBarAction({required IconData icon, required String tooltip, required VoidCallback? onPressed}) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: onPressed != null ? Colors.white : Colors.white.withOpacity(0.5),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(color: isDrawing ? Colors.green : Colors.grey, shape: BoxShape.circle),
    );
  }
}