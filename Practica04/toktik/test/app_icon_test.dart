import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toktik/config/theme/season_icons.dart';
import 'package:toktik/domain/entities/app_icon.dart';
import 'package:toktik/domain/entities/season.dart';
import 'package:toktik/infrastructure/services/native_app_icon_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('toktik/app_icon');
  final calls = <String>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'setIcon');
          calls.add(call.arguments as String);
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test('Iconos disponibles corresponden a las temporadas y al fallback', () {
    expect(appIconForSeason(Season.halloween), AppIcon.halloween);
    expect(appIconForSeason(Season.christmas), AppIcon.christmas);
    expect(appIconForSeason(Season.valentines), AppIcon.valentines);
    expect(
      SeasonIcons.assetFor(Season.normal),
      'assets/icons/vdry_launcher.png',
    );
    expect(
      SeasonIcons.assetFor(Season.halloween),
      'assets/icons/vdry-halloween.png',
    );
    expect(
      SeasonIcons.assetFor(Season.christmas),
      'assets/icons/vdry-Christmas.png',
    );
    expect(
      SeasonIcons.assetFor(Season.valentines),
      'assets/icons/vdry-valentines.png',
    );
  });
  test(
    'Android cambia icono y no repite cambios de la misma temporada',
    () async {
      final service = PlatformAppIconService(
        channel: channel,
        platform: TargetPlatform.android,
      );
      await service.applySeason(Season.halloween);
      await service.applySeason(Season.halloween);
      await service.applySeason(Season.christmas);
      await service.applySeason(Season.normal);
      await service.applySeason(Season.valentines);
      expect(calls, ['halloween', 'christmas', 'normal', 'valentines']);
    },
  );
  test('Cambios rápidos se aplican en orden', () async {
    final gate = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.arguments as String);
          if (calls.length == 1) await gate.future;
          return null;
        });
    final service = PlatformAppIconService(
      channel: channel,
      platform: TargetPlatform.iOS,
    );
    final halloween = service.applySeason(Season.halloween);
    final christmas = service.applySeason(Season.christmas);
    await Future<void>.delayed(Duration.zero);
    expect(calls, ['halloween']);
    gate.complete();
    await Future.wait([halloween, christmas]);
    expect(calls, ['halloween', 'christmas']);
  });
  test('Un fallo nativo permite reintentar la misma temporada', () async {
    var attempts = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          attempts++;
          if (attempts == 1) throw PlatformException(code: 'BUSY');
          return null;
        });
    final service = PlatformAppIconService(
      channel: channel,
      platform: TargetPlatform.iOS,
    );
    await expectLater(
      service.applySeason(Season.halloween),
      throwsA(isA<PlatformException>()),
    );
    await service.applySeason(Season.halloween);
    expect(attempts, 2);
  });
  test('Escritorio no invoca un canal móvil inexistente', () async {
    final service = PlatformAppIconService(
      channel: channel,
      platform: TargetPlatform.macOS,
    );
    await service.applySeason(Season.halloween);
    expect(calls, isEmpty);
  });
}
