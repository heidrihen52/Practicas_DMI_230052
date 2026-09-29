import 'package:flutter/material.dart';
import 'package:toktik/config/domain/entities/video_post.dart';

class DiscoverProvider extends ChangeNotifier {
  bool initialLoading = true;
  List<VideoPost>videos=[];
  Future<void> loadNextPage() async{
    // todo:cargar videos
    notifyListeners();
  }
}