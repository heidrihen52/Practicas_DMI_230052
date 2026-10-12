import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_world_app/main.dart';

void main() {
  testWidgets('Incremento, decremento, colores y ambos reinicios', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('0'), findsOneWidget);
    expect(tester.widget<Text>(find.text('0')).style?.color, Colors.blue);
    await tester.tap(find.byIcon(Icons.plus_one));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Click'), findsOneWidget);
    expect(tester.widget<Text>(find.text('1')).style?.color, Colors.green);
    await tester.tap(find.byIcon(Icons.exposure_minus_1_outlined));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.exposure_minus_1_outlined));
    await tester.pump();
    expect(find.text('-1'), findsOneWidget);
    expect(find.text('Clicks'), findsOneWidget);
    expect(tester.widget<Text>(find.text('-1')).style?.color, Colors.red);
    await tester.tap(find.byIcon(Icons.refresh_rounded).last);
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.plus_one));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.refresh_rounded).first);
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(360, 640), const Size(412, 915), const Size(640, 360)]) {
    testWidgets('Interfaz y botones en ${size.width} x ${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MyApp());
      expect(find.text('Counter Functions'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.plus_one));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh_rounded).last);
      await tester.pump();
      expect(find.text('0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
