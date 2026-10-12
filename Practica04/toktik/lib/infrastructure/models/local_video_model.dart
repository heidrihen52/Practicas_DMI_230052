import 'package:toktik/domain/entities/video_post.dart';

class LocalVideoModel {
  final String name;
  final String videoUrl;
  final int likes;
  final int views;

  LocalVideoModel({
    required this.name,
    required this.videoUrl,
    this.likes = 0,
    this.views = 0,
  });

  factory LocalVideoModel.fromJson(Map<String, dynamic> json) =>
      LocalVideoModel(
        name: json['name'] ?? 'No name',
        videoUrl: json['videoUrl'],
        likes: json['likes'] ?? 0,
        views: json['views'] ?? 0,
      );

  VideoPost toVideoPostEntity() => VideoPost(
    caption: name,
    description:
        '$name. Una pequeña escena de la vida cotidiana, capturada para compartir lo que suele pasar desapercibido. Desliza hacia los lados para descubrir más videos y toca el corazón para guardar este momento en tus favoritos.',
    videoUrl: videoUrl,
    likes: likes,
    views: views,
  );
}
