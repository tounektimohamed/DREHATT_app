import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:DREHATT_app/screens2/jeojson/SigWeb.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore_mocks/cloud_firestore_mocks.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

// Mock Google Map Controller
class MockGoogleMapController extends Fake implements GoogleMapController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirestoreInstance mockFirestore;
  late MockFirebaseStorage mockStorage;

  setUpAll(() async {
    // Initialiser Firebase avec de fausses options
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'fake',
        appId: 'fake',
        messagingSenderId: 'fake',
        projectId: 'fake',
      ),
    );

    // Initialiser Firestore et Storage mocks
    mockFirestore = MockFirestoreInstance();
    mockStorage = MockFirebaseStorage();
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

    // Vérifier les boutons de la barre d’action
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

  testWidgets('Upload progress indicator appears', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SigWeb(title: 'Test SigWeb'),
      ),
    );

    await tester.pumpAndSettle();

    // Simuler le début de l’upload
    final state =
        tester.state<_SigWebState>(find.byType(SigWeb)); // accéder à l'état
    state.setState(() {
      state.uploadingData = true;
      state.uploadProgress = 50;
    });

    await tester.pumpAndSettle();

    // Vérifier que le progress indicator est visible
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Téléchargement en cours...'), findsOneWidget);
  });
}
