import 'package:flutter/material.dart';

import '../../domain/entities/season.dart';
import '../../domain/entities/video_post.dart';
import '../../domain/repositories/preferences_repository.dart';

class PreferencesProvider extends ChangeNotifier {
  final PreferencesRepository repository;
  final Set<String> _pending = {};
  bool _settingsPending = false;
  PreferencesProvider(this.repository);
  Season get season =>
      repository.seasonOverride ?? seasonForDate(DateTime.now());
  void refreshDate() => notifyListeners();
  Future<void> toggleLike(VideoPost video) async {
    if (!_pending.add(video.id)) return;
    try {
      await repository.toggleLike(video);
      notifyListeners();
    } finally {
      _pending.remove(video.id);
    }
  }

  Future<void> _setting(Future<void> Function() save) async {
    if (_settingsPending) return;
    _settingsPending = true;
    try {
      await save();
      notifyListeners();
    } finally {
      _settingsPending = false;
    }
  }

  Future<void> setSeason(Season? season) =>
      _setting(() => repository.setSeason(season));
  Future<void> toggleMuted() =>
      _setting(() => repository.setMuted(!repository.muted));
  Future<void> toggleAudio() =>
      _setting(() => repository.setSeasonalAudio(!repository.seasonalAudio));
}
