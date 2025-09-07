import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:DREHATT_app/screens2/jeojson/SigWeb.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test SigWeb page loads', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SigWeb(title: 'Test SIG Web'),
    ));

    // Vérifie si le titre est présent
    expect(find.text('Suivi des PAUS'), findsOneWidget);

    // Vérifie si le FloatingActionButton est présent
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
