import 'package:flutter/material.dart';
import 'package:toktik/domain/entities/video_post.dart';
import 'package:toktik/infrastructure/models/local_video_model.dart';
import 'package:toktik/domain/repositories/video_posts_repositories.dart';
import 'package:toktik/shared/data/local_video_posts.dart';



class DiscoverProvider extends ChangeNotifier {
  final VideoPostRepository videosRepository;

  bool initialLoading = true;
  List<VideoPost> videos = [];

  DiscoverProvider({
    required this.videosRepository
  });

  //new(this.videosRepository);

  Future<void> loadNextPage() async {

    // await Future.delayed( const Duration(seconds: 2) );

    final newVideos = await videosRepository.getTrendingVideosByPage(1);
    
    videos.addAll( newVideos );
    initialLoading = false;
    notifyListeners();
  }


}