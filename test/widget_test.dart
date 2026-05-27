import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:velocy_app/main.dart';

void main() {
  testWidgets('renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const VelocyApp());

    expect(find.text('Velocy'), findsOneWidget);
    expect(find.byIcon(Icons.directions_bike), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Masuk untuk mulai meminjam sepeda'), findsOneWidget);
  });
}
