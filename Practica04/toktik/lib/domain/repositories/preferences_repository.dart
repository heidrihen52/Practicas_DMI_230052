import '../entities/season.dart';
import '../entities/video_post.dart';

abstract class PreferencesRepository {
  Season? get seasonOverride;
  bool get muted;
  bool get seasonalAudio;
  List<VideoPost> get favorites;
  bool isLiked(VideoPost video);
  int likes(VideoPost video);
  Future<void> toggleLike(VideoPost video);
  Future<void> setSeason(Season? season);
  Future<void> setMuted(bool muted);
  Future<void> setSeasonalAudio(bool enabled);
}
