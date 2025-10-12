import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'package:DREHATT_app/screens2/jeojson/SigWeb.dart';

// Mocks pour les dépendances Firebase
class MockFirebaseStorage extends Mock implements FirebaseStorage {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockReference extends Mock implements Reference {}
class MockListResult extends Mock implements ListResult {}
class MockFilePickerResult extends Mock implements FilePickerResult {}
class MockPlatformFile extends Mock implements PlatformFile {}
class MockFirebaseApp extends Mock implements FirebaseApp {}

// Mocks pour les dépendances HTTP
class MockClient extends Mock implements http.Client {}
class MockResponse extends Mock implements http.Response {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialisation des mocks
  final mockFirebaseStorage = MockFirebaseStorage();
  final mockFirebaseFirestore = MockFirebaseFirestore();
  final mockStorageReference = MockReference();
  final mockListResult = MockListResult();
  final mockFilePicker = MockFilePickerResult();
  final mockPlatformFile = MockPlatformFile();
  final mockHttpClient = MockClient();
  final mockHttpResponse = MockResponse();
  final mockFirebaseApp = MockFirebaseApp();

  setUpAll(() async {
    // Configuration des mocks pour Firebase
    when(mockFirebaseStorage.ref()).thenReturn(mockStorageReference);
    when(mockStorageReference.child(any)).thenReturn(mockStorageReference);
    
    // Configuration pour l'initialisation de Firebase
    when(mockFirebaseApp.name).thenReturn('[DEFAULT]');
    when(mockFirebaseApp.options).thenReturn(FirebaseOptions(
      apiKey: 'test',
      appId: 'test',
      messagingSenderId: 'test',
      projectId: 'test',
    ));
  });

  group('SigWeb Integration Tests', () {
    testWidgets('App UI loads correctly with all elements', (WidgetTester tester) async {
      // Construire notre app et déclencher un frame
      await tester.pumpWidget(MaterialApp(
        home: SigWeb(title: 'Test SIG Web'),
      ));

      // Vérifier que le titre de l'appbar est présent
      expect(find.text('Suivi des PAUS'), findsOneWidget);

      // Vérifier la présence des boutons d'action dans l'AppBar
      expect(find.byIcon(Icons.web), findsOneWidget);
      expect(find.byIcon(Icons.web_asset), findsOneWidget);
      expect(find.byIcon(Icons.change_circle), findsOneWidget);
      expect(find.byIcon(Icons.map_sharp), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.byIcon(Icons.layers), findsOneWidget);

      // Vérifier la présence du FloatingActionButton
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('GeoJSON selection dialog appears', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SigWeb(title: 'Test SIG Web'),
      ));

      // Simuler l'appui sur le bouton de sélection de fichier
      await tester.tap(find.byIcon(Icons.folder_open));
      await tester.pumpAndSettle();

      // Vérifier que le dialogue apparaît
      expect(find.text('Sélectionner un fichier GeoJSON'), findsOneWidget);
    });

    testWidgets('Map type selection dialog appears', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SigWeb(title: 'Test SIG Web'),
      ));

      // Simuler l'appui sur le bouton de changement de type de carte
      await tester.tap(find.byIcon(Icons.layers));
      await tester.pumpAndSettle();

      // Vérifier que le dialogue apparaît
      expect(find.text('Sélectionner le type de carte'), findsOneWidget);
      
      // Vérifier les options de type de carte
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Satellite'), findsOneWidget);
      expect(find.text('Terrain'), findsOneWidget);
      expect(find.text('Hybride'), findsOneWidget);
    });

    testWidgets('Loading indicator appears during GeoJSON processing', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SigWeb(title: 'Test SIG Web'),
      ));

      // Accéder à l'état du widget pour simuler le chargement
      final state = tester.state<_SigWebState>(find.byType(SigWeb));
      
      // Simuler le chargement de données
      state.setState(() {
        state.loadingData = true;
      });
      await tester.pump();

      // Vérifier que l'indicateur de chargement est affiché
      expect(find.text('Chargement des données...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Upload progress indicator appears during file upload', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SigWeb(title: 'Test SIG Web'),
      ));

      // Accéder à l'état du widget pour simuler l'upload
      final state = tester.state<_SigWebState>(find.byType(SigWeb));
      
      // Simuler l'upload de données
      state.setState(() {
        state.uploadingData = true;
        state.uploadProgress = 50.0;
      });
      await tester.pump();

      // Vérifier que l'indicateur de progression est affiché
      expect(find.text('Téléchargement en cours...'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });
  });

  group('GeoJSON Processing Tests', () {
    testWidgets('Polygons are correctly parsed from GeoJSON', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SigWeb(title: 'Test SIG Web'),
      ));

      final state = tester.state<_SigWebState>(find.byType(SigWeb));
      
      // Données GeoJSON de test avec un polygone
      final testGeoJson = '''
      {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {
              "type": "Polygon",
              "coordinates": [[
                [10.0, 32.0],
                [10.1, 32.0],
                [10.1, 32.1],
                [10.0, 32.1],
                [10.0, 32.0]
              ]]
            },
            "properties": {
              "Layer": "1 UAa1",
              "fill": "#ff0000",
              "stroke": "#000000",
              "stroke-width": 2,
              "fill-opacity": 0.5
            }
          }
        ]
      }
      ''';

      // Simuler la réponse HTTP
      when(mockHttpResponse.body).thenReturn(testGeoJson);
      when(mockHttpClient.get(any)).thenAnswer((_) async => mockHttpResponse);

      // Appeler la méthode de traitement GeoJSON
      await state.loadGeoJsonFromStorage('test.geojson');
      await tester.pumpAndSettle();

      // Vérifier que le polygone a été créé
      expect(state.polygons.length, 1);
      
      // Vérifier les propriétés du polygone
      final polygon = state.polygons.first;
      expect(polygon.points.length, 5);
      expect(polygon.fillColor, Color(0x80ff0000)); // Rouge avec opacité 0.5
      expect(polygon.strokeColor, Colors.black);
    });

    testWidgets('Polylines are correctly parsed from GeoJSON', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SigWeb(title: 'Test SIG Web'),
      ));

      final state = tester.state<_SigWebState>(find.byType(SigWeb));
      
      // Données GeoJSON de test avec une ligne
      final testGeoJson = '''
      {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {
              "type": "LineString",
              "coordinates": [
                [10.0, 32.0],
                [10.1, 32.1],
                [10.2, 32.2]
              ]
            },
            "properties": {
              "name": "Test Line"
            }
          }
        ]
      }
      ''';

      // Simuler la réponse HTTP
      when(mockHttpResponse.body).thenReturn(testGeoJson);
      when(mockHttpClient.get(any)).thenAnswer((_) async => mockHttpResponse);

      // Appeler la méthode de traitement GeoJSON
      await state.loadGeoJsonFromStorage('test.geojson');
      await tester.pumpAndSettle();

      // Vérifier que la polyligne a été créée
      expect(state.polylines.length, 1);
      
      // Vérifier les propriétés de la polyligne
      final polyline = state.polylines.first;
      expect(polyline.points.length, 3);
      expect(polyline.color, Colors.red);
    });
  });

  group('UI Interaction Tests', () {
    testWidgets('Tapping polygon shows info dialog', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SigWeb(title: 'Test SIG Web'),
      ));

      final state = tester.state<_SigWebState>(find.byType(SigWeb));
      
      // Créer un polygone de test
      final testPolygon = Polygon(
        polygonId: PolygonId('test_polygon'),
        points: [
          LatLng(32.0, 10.0),
          LatLng(32.1, 10.0),
          LatLng(32.1, 10.1),
          LatLng(32.0, 10.1),
        ],
        strokeColor: Colors.black,
        strokeWidth: 2,
        fillColor: Colors.red.withOpacity(0.5),
      );

      // Ajouter le polygone à l'état
      state.setState(() {
        state.polygons = {testPolygon};
      });
      await tester.pump();

      // Simuler le tap sur le polygone
      state._showPolygonInfo({
        'Layer': '1 UAa1',
        'fill': '#ff0000',
        'stroke': '#000000',
        'stroke-width': 2,
        'fill-opacity': 0.5,
        'description': 'Test polygon'
      });

      await tester.pumpAndSettle();

      // Vérifier que le dialogue d'information apparaît
      expect(find.text('Informations du polygone'), findsOneWidget);
      expect(find.text('1 UAa1'), findsOneWidget);
    });

    testWidgets('Map type changes correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SigWeb(title: 'Test SIG Web'),
      ));

      final state = tester.state<_SigWebState>(find.byType(SigWeb));
      
      // Vérifier le type de carte initial
      expect(state._currentMapType, MapType.normal);
      
      // Changer le type de carte
      state._changeMapType(MapType.satellite);
      await tester.pump();
      
      // Vérifier que le type de carte a changé
      expect(state._currentMapType, MapType.satellite);
    });
  });
}