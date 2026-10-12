import 'package:flutter/services.dart';

import '../../domain/datasources/video_posts_datasource.dart';
import '../../domain/entities/video_post.dart';
import '../models/local_video_model.dart';
import '../../shared/data/local_video_posts.dart';

class LocalVideoDatasource implements VideoPostDatasource {
  final Future<Set<String>> Function()? assetPaths;
  LocalVideoDatasource({this.assetPaths});
  Future<Set<String>> _assets() async =>
      (await AssetManifest.loadFromAssetBundle(rootBundle))
          .listAssets()
          .toSet();
  @override
  Future<List<VideoPost>> getFavoriteVideosByUser(String userID) async => [];
  @override
  Future<List<VideoPost>> getTrendingVideosByPage(int page) async {
    if (page != 1) return [];
    final available = await (assetPaths ?? _assets)();
    final metadata = {for (final video in videoPosts) video['videoUrl']: video};
    final paths =
        available
            .where(
              (path) => RegExp(
                r'^assets/videos/[^/]+\.mp4$',
                caseSensitive: false,
              ).hasMatch(path),
            )
            .toList()
          ..sort((a, b) {
            final left = int.tryParse(a.split('/').last.split('.').first);
            final right = int.tryParse(b.split('/').last.split('.').first);
            return left != null && right != null
                ? left.compareTo(right)
                : a.compareTo(b);
          });
    final videos = paths.map((path) {
      final name = path.split('/').last.split('.').first;
      return LocalVideoModel.fromJson(
        metadata[path] ??
            {'name': 'Video $name', 'videoUrl': path, 'likes': 0, 'views': 0},
      ).toVideoPostEntity();
    }).toList();
    if (videos.isEmpty) {
      throw StateError('No se instalaron los videos locales de assets/videos.');
    }
    return videos;
  }
}
