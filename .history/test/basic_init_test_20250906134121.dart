import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:DREHATT_app/screens2/jeojson/SigWeb.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Test SIG Web App", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SigWeb(title: 'Test SIG Web')));

    // Vérifier que l'UI se charge
    expect(find.text('Suivi des PAUS'), findsOneWidget);

    // Vérifier la présence des boutons
    expect(find.byIcon(Icons.layers), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
