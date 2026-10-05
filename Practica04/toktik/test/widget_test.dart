import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toktik/main.dart';

void main() {
  testWidgets('MyApp builds the discover screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
