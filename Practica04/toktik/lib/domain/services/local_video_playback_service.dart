/// Resuelve la variante local compatible sin cambiar la identidad del video.
abstract class LocalVideoPlaybackService {
  Future<String> resolve(String originalAsset);
}
