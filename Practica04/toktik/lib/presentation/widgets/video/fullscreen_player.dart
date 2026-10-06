import 'package:flutter/material.dart';
import 'package:toktik/presentation/widgets/video/video_background.dart';
import 'package:video_player/video_player.dart';

class FullScreenPlayer extends StatefulWidget {
  final String videoUrl;
  final String caption;

  const FullScreenPlayer({
    super.key,
    required this.videoUrl,
    required this.caption,
  });

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  late VideoPlayerController controller;

  @override
  void initState() {
    super.initState();

    controller = _createController(widget.videoUrl)
      ..setVolume(0)
      ..setLooping(true)
      ..play();
  }

  VideoPlayerController _createController(String source) {
    final uri = Uri.tryParse(source);
    final isNetwork = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    if (isNetwork) {
      return VideoPlayerController.networkUrl(
        Uri.parse(_directMediaUrl(source)),
      );
    }

    return VideoPlayerController.asset(source);
  }

  /// Drive /view links are HTML pages, not MP4 streams.
  String _directMediaUrl(String url) {
    final match = RegExp(r'drive\.google\.com/file/d/([^/?]+)').firstMatch(url);
    if (match != null) {
      return 'https://drive.google.com/uc?export=download&id=${match.group(1)}';
    }
    return url;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: controller.initialize(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Icon(Icons.error_outline, color: Colors.white, size: 40),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        return GestureDetector(
          onTap: () {
            if (controller.value.isPlaying) {
              controller.pause();
              return;
            }
            controller.play();
          },
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(controller),

                // Gradiente
                VideoBackground(stops: const [0.8, 1.0]),

                // Texto
                Positioned(
                  bottom: 50,
                  left: 20,
                  child: _VideoCaption(caption: widget.caption),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VideoCaption extends StatelessWidget {
  final String caption;

  const _VideoCaption({required this.caption});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return SizedBox(
      width: size.width * 0.6,
      child: Text(caption, maxLines: 2, style: titleStyle),
    );
  }
}
