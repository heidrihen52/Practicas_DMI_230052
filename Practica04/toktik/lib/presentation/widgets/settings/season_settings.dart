import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_theme.dart';
import '../../../config/theme/season_icons.dart';
import '../../../domain/entities/season.dart';
import '../../providers/preferences_provider.dart';

class SeasonSettings extends StatelessWidget {
  const SeasonSettings({super.key});
  Future<void> _save(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar la preferencia.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Temporada visual y auditiva',
                style: TextStyle(fontSize: 22),
              ),
              const Text(
                'Automático: octubre, diciembre y 1–14 de febrero. La prueba se guarda en el dispositivo.',
              ),
              RadioGroup<String>(
                groupValue: prefs.repository.seasonOverride?.name ?? 'auto',
                onChanged: (value) => _save(
                  context,
                  () => prefs.setSeason(
                    value == 'auto' ? null : Season.values.byName(value!),
                  ),
                ),
                child: Column(
                  children: [
                    const RadioListTile<String>(
                      value: 'auto',
                      title: Text('Automático (fecha del dispositivo)'),
                    ),
                    for (final season in Season.values)
                      RadioListTile<String>(
                        value: season.name,
                        title: Text(SeasonStyle.forSeason(season).label),
                        secondary: Image.asset(
                          SeasonIcons.assetFor(season),
                          width: 40,
                          height: 40,
                        ),
                      ),
                  ],
                ),
              ),
              SwitchListTile(
                value: prefs.repository.seasonalAudio,
                title: const Text('Melodía al cambiar temporada'),
                subtitle: const Text('Respeta el botón de silenciar videos.'),
                onChanged: (_) => _save(context, prefs.toggleAudio),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
