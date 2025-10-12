import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:DREHATT_app/screens2/jeojson/SigWeb.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("SIG Web app loads", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SigWeb(title: 'Test SIG Web')));

    // Vérifie que l'UI de base se charge
    expect(find.text('Suivi des PAUS'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
