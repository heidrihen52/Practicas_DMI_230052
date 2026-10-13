import 'dart:async';

import 'package:video_player/video_player.dart';

import '../../../domain/entities/video_post.dart';

class PreparedRemoteVideo {
  final VideoPlayerController controller;
  late final Future<void> ready;
  PreparedRemoteVideo(String url)
    : controller = VideoPlayerController.networkUrl(Uri.parse(url)) {
    ready = _prepare();
    // La precarga puede fallar antes de que exista un widget que la observe.
    unawaited(ready.catchError((Object _) {}));
  }
  Future<void> _prepare() async {
    await controller.initialize().timeout(const Duration(seconds: 25));
    await controller.setVolume(0);
    await controller.setLooping(true);
  }

  Future<void> dispose() => controller.dispose().catchError((Object _) {});
}

/// Solo el video actual y el siguiente: no descarga todo el feed ni reproduce
/// audio en segundo plano. Reutiliza el controlador preparado al avanzar.
class RemoteVideoPreloader {
  final _entries = <String, PreparedRemoteVideo>{};
  final _retired = <Future<void>>{};
  PreparedRemoteVideo? forVideo(VideoPost video) => _entries[video.id];

  void retain(Iterable<VideoPost> videos) {
    final wanted = videos
        .where((v) => v.source != VideoSource.local && v.supportsDirectPlayback)
        .take(2)
        .toList();
    final ids = wanted.map((v) => v.id).toSet();
    for (final id in _entries.keys.toList()) {
      if (!ids.contains(id)) {
        final disposal = _entries.remove(id)!.dispose();
        _retired.add(disposal);
        unawaited(
          disposal.then((_) {
            _retired.remove(disposal);
          }),
        );
      }
    }
    for (final video in wanted) {
      _entries.putIfAbsent(video.id, () => PreparedRemoteVideo(video.videoUrl));
    }
  }

  Future<void> dispose() async {
    retain([]);
    await Future.wait(_retired.toList());
  }
}
