import 'dart:async';

import '../../domain/repositories/feed_repository.dart';
import '../../domain/entities/video_post.dart';
import '../../domain/repositories/video_posts_repository.dart';
import '../../domain/repositories/preferences_repository.dart';

class DiscoverFeedRepository implements ProgressiveFeedRepository {
  final Map<String, VideoPostRepository> sources;
  DiscoverFeedRepository(this.sources);
  @override
  Future<FeedPage> load(int page) => loadProgressively(page).last;

  @override
  Stream<FeedPage> loadProgressively(int page) {
    final stream = StreamController<FeedPage>();
    final warnings = <String>[];
    final batches = List.generate(sources.length, (_) => <VideoPost>[]);
    var remaining = sources.length;
    if (remaining == 0) {
      stream.add(const FeedPage([], []));
      stream.close();
      return stream.stream;
    }
    var position = 0;
    for (final entry in sources.entries) {
      final slot = position++;
      () async {
        try {
          final result = await entry.value.getTrendingVideosByPage(page);
          batches[slot] = result
              .where(
                (v) =>
                    v.source != VideoSource.local && v.supportsDirectPlayback,
              )
              .toList();
        } catch (_) {
          warnings.add(entry.key);
        }
        final videos = <VideoPost>[];
        for (var index = 0; batches.any((b) => index < b.length); index++) {
          for (final batch in batches) {
            if (index < batch.length) videos.add(batch[index]);
          }
        }
        stream.add(FeedPage(videos, List.of(warnings)));
        if (--remaining == 0) await stream.close();
      }();
    }
    return stream.stream;
  }
}

/// Feed local independiente: nunca consulta las APIs de Descubrir.
class ForYouFeedRepository implements FeedRepository {
  final VideoPostRepository local;
  ForYouFeedRepository(this.local);
  @override
  Future<FeedPage> load(int page) async {
    final videos = await local.getTrendingVideosByPage(page);
    return FeedPage(
      videos.where((video) => video.source == VideoSource.local).toList(),
      [],
    );
  }
}

class FavoritesFeedRepository implements FavoritesRepository {
  final PreferencesRepository preferences;
  FavoritesFeedRepository(this.preferences);
  @override
  List<VideoPost> get savedVideos =>
      preferences.favorites.where((v) => v.supportsDirectPlayback).toList();
  @override
  Future<FeedPage> load(int page) async =>
      FeedPage(page == 1 ? savedVideos : [], []);
}
