import 'package:web/web.dart' as web;

import '../../config/theme/season_icons.dart';
import '../../domain/entities/season.dart';
import '../../domain/services/app_icon_service.dart';

class PlatformAppIconService implements AppIconService {
  @override
  Future<void> applySeason(Season season) async {
    final head = web.document.head;
    if (head == null) return;
    final existing = web.document.querySelector('link[rel="icon"]');
    final icon = (existing as web.HTMLLinkElement?) ?? web.HTMLLinkElement();
    icon.rel = 'icon';
    icon.type = 'image/png';
    icon.href = 'assets/${SeasonIcons.assetFor(season)}';
    if (existing == null) head.appendChild(icon);
  }
}
