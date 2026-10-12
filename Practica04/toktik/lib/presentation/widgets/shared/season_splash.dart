import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_theme.dart';
import '../../../config/theme/season_icons.dart';
import '../../providers/preferences_provider.dart';

/// Las preferencias se cargan antes de runApp: no aparece el tema por defecto.
class SeasonSplash extends StatelessWidget {
  const SeasonSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final season = context.watch<PreferencesProvider>().season;
    return ColoredBox(
      color: const Color(0xFF101015),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(SeasonIcons.assetFor(season), width: 160, height: 160),
            const SizedBox(height: 20),
            Text(
              'Vdry · ${SeasonStyle.forSeason(season).label}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
