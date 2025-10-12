import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:DREHATT_app/screens2/jeojson/SigWeb.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialiser Firebase fake
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'fake',
        appId: 'fake',
        messagingSenderId: 'fake',
        projectId: 'fake',
      ),
    );
  });

  testWidgets('SigWeb page renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SigWeb(title: 'Test SigWeb'),
      ),
    );

    await tester.pumpAndSettle();

    // Vérifier AppBar et boutons
    expect(find.text('Suivi des PAUS'), findsOneWidget);
    expect(find.byTooltip('Afficher HTML Local'), findsOneWidget);
    expect(find.byTooltip('Gérer les pages HTML'), findsOneWidget);
    expect(find.byTooltip('Convertisseur GeoJSON'), findsOneWidget);
    expect(find.byTooltip('Lecteur KML'), findsOneWidget);
    expect(find.byTooltip('Télécharger un fichier GeoJSON'), findsOneWidget);
    expect(find.byTooltip('Liste des PAUS'), findsOneWidget);
    expect(find.byTooltip('Changer le type de carte'), findsOneWidget);

    // Vérifier présence de GoogleMap
    expect(find.byType(GoogleMap), findsOneWidget);

    // Vérifier FloatingActionButton
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Map type selection dialog opens', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SigWeb(title: 'Test SigWeb'),
      ),
    );

    await tester.pumpAndSettle();

    // Ouvrir le dialogue de changement de type de carte
    await tester.tap(find.byTooltip('Changer le type de carte'));
    await tester.pumpAndSettle();

    expect(find.text('Sélectionner le type de carte'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Satellite'), findsOneWidget);
    expect(find.text('Terrain'), findsOneWidget);
    expect(find.text('Hybride'), findsOneWidget);
  });

  testWidgets('GeoJSON selection dialog opens', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SigWeb(title: 'Test SigWeb'),
      ),
    );

    await tester.pumpAndSettle();

    // Ouvrir le dialogue de sélection GeoJSON
    await tester.tap(find.byTooltip('Liste des PAUS'));
    await tester.pumpAndSettle();

    expect(find.text('Sélectionner un fichier GeoJSON'), findsOneWidget);
  });
}
