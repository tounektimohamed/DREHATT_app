import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:DREHATT_app/screens2/jeojson/SigWeb.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Mock Firebase
class MockFirebaseApp extends Mock implements FirebaseApp {}
class MockFirebaseStorage extends Mock implements FirebaseStorage {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockGoogleMapController extends Mock implements GoogleMapController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mock Firebase.initializeApp
    Firebase.initializeApp = () async => MockFirebaseApp();
  });

  testWidgets('SigWeb page renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SigWeb(title: 'Test SigWeb'),
      ),
    );

    await tester.pumpAndSettle();

    // Vérifier que l'AppBar est présent
    expect(find.text('Suivi des PAUS'), findsOneWidget);

    // Vérifier la présence du GoogleMap
    expect(find.byType(GoogleMap), findsOneWidget);

    // Vérifier la présence du FloatingActionButton
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Vérifier que les boutons d'action dans l'AppBar sont présents
    expect(find.byTooltip('Afficher HTML Local'), findsOneWidget);
    expect(find.byTooltip('Gérer les pages HTML'), findsOneWidget);
    expect(find.byTooltip('Convertisseur GeoJSON'), findsOneWidget);
    expect(find.byTooltip('Lecteur KML'), findsOneWidget);
    expect(find.byTooltip('Télécharger un fichier GeoJSON'), findsOneWidget);
    expect(find.byTooltip('Liste des PAUS'), findsOneWidget);
    expect(find.byTooltip('Changer le type de carte'), findsOneWidget);
  });

  testWidgets('Map type selection dialog opens', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SigWeb(title: 'Test SigWeb'),
      ),
    );

    await tester.pumpAndSettle();

    // Ouvrir le dialogue type de carte
    await tester.tap(find.byTooltip('Changer le type de carte'));
    await tester.pumpAndSettle();

    // Vérifier que le dialogue s'ouvre
    expect(find.text('Sélectionner le type de carte'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Satellite'), findsOneWidget);
    expect(find.text('Terrain'), findsOneWidget);
    expect(find.text('Hybride'), findsOneWidget);
  });

  testWidgets('GeoJSON selection dialog opens', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SigWeb(title: 'Test SigWeb'),
      ),
    );

    await tester.pumpAndSettle();

    // Ouvrir le dialogue de sélection GeoJSON
    await tester.tap(find.byTooltip('Liste des PAUS'));
    await tester.pumpAndSettle();

    // Vérifier que le dialogue s'ouvre
    expect(find.text('Sélectionner un fichier GeoJSON'), findsOneWidget);
  });
}
