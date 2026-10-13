import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/app_icon.dart';
import '../../domain/entities/season.dart';
import '../../domain/services/app_icon_service.dart';

class PlatformAppIconService implements AppIconService {
  final MethodChannel channel;
  final TargetPlatform? platform;
  AppIcon? _applied;
  Future<void> _updates = Future.value();
  PlatformAppIconService({
    this.channel = const MethodChannel('toktik/app_icon'),
    this.platform,
  });

  @override
  Future<void> applySeason(Season season) {
    final icon = appIconForSeason(season);
    final update = _updates.then((_) async {
      if (_applied == icon) return;
      final target = platform ?? defaultTargetPlatform;
      if (target == TargetPlatform.android || target == TargetPlatform.iOS) {
        await channel.invokeMethod<void>('setIcon', icon.name);
      }
      _applied = icon;
    });
    // Serializar cambios rápidos y permitir reintentar si el sistema rechaza uno.
    _updates = update.catchError((Object _) {});
    return update;
  }
}
