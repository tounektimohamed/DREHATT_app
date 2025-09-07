import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:DREHATT_app/screens2/jeojson/SigWeb.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test initialisation de SigWeb', (WidgetTester tester) async {
    // Construire l'application
    await tester.pumpWidget(MaterialApp(
      home: SigWeb(title: 'Test Initialisation'),
    ));

    // Vérifier que le titre est présent
    expect(find.text('Suivi des PAUS'), findsOneWidget);

    // Vérifier qu'il y a un FloatingActionButton
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
