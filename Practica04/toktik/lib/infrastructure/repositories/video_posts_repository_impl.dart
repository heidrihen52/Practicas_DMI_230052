import '../../domain/datasources/video_posts_datasource.dart';
import '../../domain/entities/video_post.dart';
import '../../domain/repositories/video_posts_repository.dart';

class VideoPostsRepositoryImpl implements VideoPostRepository {
  final VideoPostDatasource videosDatasource;
  VideoPostsRepositoryImpl({required this.videosDatasource});
  @override
  Future<List<VideoPost>> getFavoriteVideosByUser(String userID) =>
      videosDatasource.getFavoriteVideosByUser(userID);
  @override
  Future<List<VideoPost>> getTrendingVideosByPage(int page) =>
      videosDatasource.getTrendingVideosByPage(page);
}
