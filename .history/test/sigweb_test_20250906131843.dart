import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:DREHATT_app/screens2/jeojson/SigWeb.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SigWeb Web Tests', () {
    testWidgets('SigWeb UI loads correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SigWeb(title: 'Test SIG Web'),
      ));

      // Vérifie si le titre est présent
      expect(find.text('Suivi des PAUS'), findsOneWidget);

      // Vérifie si le FloatingActionButton est présent
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Vérifie la présence des boutons dans l'AppBar
      expect(find.byIcon(Icons.web), findsOneWidget);
      expect(find.byIcon(Icons.web_asset), findsOneWidget);
      expect(find.byIcon(Icons.change_circle), findsOneWidget);
      expect(find.byIcon(Icons.map_sharp), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.byIcon(Icons.layers), findsOneWidget);
    });

    testWidgets('Mock upload GeoJSON', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SigWeb(title: 'Test SIG Web'),
      ));

      final state = tester.state<_SigWebState>(find.byType(SigWeb));

      // Mock data GeoJSON minimal
      final mockGeoJson = '''
      {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {
              "type": "Polygon",
              "coordinates": [[[10.0, 32.0],[10.1,32.0],[10.1,32.1],[10.0,32.1],[10.0,32.0]]]
            },
            "properties": {
              "Layer": "UAa1",
              "fill": "#ff0000"
            }
          }
        ]
      }
      ''';

      // Charger le GeoJSON mocké
      await state.loadGeoJsonFromStorage('mock.geojson');
      await tester.pumpAndSettle();

      // Vérifie que le polygone est ajouté
      expect(state.polygons.length, 1);
    });
  });
}
