import '../entities/season.dart';

/// Activar el volumen no vuelve a disparar el sonido de la temporada.
class SeasonalAudioPolicy {
  Season? _lastSeason;

  bool shouldPlay(Season season, {required bool muted, required bool enabled}) {
    final changed = _lastSeason != season;
    _lastSeason = season;
    return changed && !muted && enabled;
  }
}
