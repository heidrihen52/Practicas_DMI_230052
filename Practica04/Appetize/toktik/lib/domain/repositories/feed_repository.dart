import '../entities/video_post.dart';

class FeedPage {
  final List<VideoPost> videos;
  final List<String> unavailableSources;
  const FeedPage(this.videos, this.unavailableSources);
}

abstract class FeedRepository {
  Future<FeedPage> load(int page);
}

abstract class ProgressiveFeedRepository implements FeedRepository {
  Stream<FeedPage> loadProgressively(int page);
}

abstract class FavoritesRepository implements FeedRepository {
  List<VideoPost> get savedVideos;
}
