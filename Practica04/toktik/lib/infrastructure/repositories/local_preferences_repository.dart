import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/season.dart';
import '../../domain/entities/video_post.dart';
import '../../domain/repositories/preferences_repository.dart';

class LocalPreferencesRepository implements PreferencesRepository {
  final SharedPreferences storage;
  Map<String, dynamic> _data = {};
  Future<void> _writes = Future.value();
  Future<void> _update(Map<String, dynamic> Function() next) {
    final result = _writes.then((_) => _save(next()));
    _writes = result.catchError((Object _) {});
    return result;
  }

  LocalPreferencesRepository(this.storage) {
    try {
      final decoded = jsonDecode(
        storage.getString('toktik.preferences.v1') ?? '{}',
      );
      if (decoded is Map<String, dynamic>) _data = decoded;
    } on FormatException {
      _data = {};
    }
  }
  Map<String, dynamic> get _saved =>
      Map<String, dynamic>.from(_data['likes'] as Map? ?? {});
  @override
  Season? get seasonOverride {
    for (final season in Season.values) {
      if (season.name == _data['season']) return season;
    }
    return null;
  }

  @override
  bool get muted => _data['muted'] as bool? ?? false;
  @override
  bool get seasonalAudio => _data['audio'] as bool? ?? true;
  @override
  List<VideoPost> get favorites => _saved.values
      .whereType<Map>()
      .where((entry) => entry['liked'] == true)
      .map(
        (entry) => VideoPost.fromJson(
          Map<String, dynamic>.from(entry['video'] as Map),
        ),
      )
      .toList();
  @override
  bool isLiked(VideoPost video) => (_saved[video.id] as Map?)?['liked'] == true;
  @override
  int likes(VideoPost video) =>
      (_saved[video.id] as Map?)?['count'] as int? ?? video.likes;
  Future<void> _save(Map<String, dynamic> next) async {
    if (!await storage.setString('toktik.preferences.v1', jsonEncode(next))) {
      throw StateError('No se pudieron guardar las preferencias');
    }
    _data = next;
  }

  @override
  Future<void> toggleLike(VideoPost video) => _update(() {
    final saved = _saved;
    final liked = !isLiked(video);
    final count = (likes(video) + (liked ? 1 : -1)).clamp(0, 1 << 53);
    saved[video.id] = {'video': video.toJson(), 'liked': liked, 'count': count};
    return {..._data, 'likes': saved};
  });
  @override
  Future<void> setSeason(Season? season) =>
      _update(() => {..._data, 'season': season?.name});
  @override
  Future<void> setMuted(bool muted) =>
      _update(() => {..._data, 'muted': muted});
  @override
  Future<void> setSeasonalAudio(bool enabled) =>
      _update(() => {..._data, 'audio': enabled});
}
