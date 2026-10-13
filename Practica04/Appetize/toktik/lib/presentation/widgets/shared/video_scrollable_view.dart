import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/entities/video_post.dart';
import '../../providers/preferences_provider.dart';
import '../video/fullscreen_player.dart';
import '../video/remote_video_preloader.dart';
import '../video/video_description.dart';
import 'video_buttons.dart';

class VideoScrollableView extends StatefulWidget {
  final List<VideoPost> videos;
  final bool active;
  final VoidCallback? onNearEnd;
  const VideoScrollableView({
    super.key,
    required this.videos,
    this.active = true,
    this.onNearEnd,
  });
  @override
  State<VideoScrollableView> createState() => _VideoScrollableViewState();
}

class _VideoScrollableViewState extends State<VideoScrollableView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  int _index = 0;
  final PageController _pages = PageController();
  final _preloader = RemoteVideoPreloader();
  @override
  void initState() {
    super.initState();
    _prepareNearby();
  }

  void _prepareNearby() {
    _preloader.retain(widget.active ? widget.videos.skip(_index).take(2) : []);
  }

  @override
  void didUpdateWidget(covariant VideoScrollableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.videos.length) {
      _index = widget.videos.isEmpty ? 0 : widget.videos.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) _pages.jumpToPage(_index);
      });
    }
    _prepareNearby();
  }

  @override
  void dispose() {
    _preloader.dispose();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final muted = context.watch<PreferencesProvider>().repository.muted;
    return PageView.builder(
      controller: _pages,
      scrollDirection: Axis.vertical,
      itemCount: widget.videos.length,
      onPageChanged: (index) {
        setState(() {
          _index = index;
          _prepareNearby();
        });
        if (index >= widget.videos.length - 2) widget.onNearEnd?.call();
      },
      itemBuilder: (context, index) {
        final video = widget.videos[index];
        return Stack(
          key: ValueKey(video.id),
          children: [
            if (widget.active && index == _index)
              Positioned.fill(
                child: FullScreenPlayer(
                  key: ValueKey(video.id),
                  video: video,
                  muted: muted,
                  prepared: _preloader.forVideo(video),
                ),
              ),
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + 20,
              left: 20,
              right: 92,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (video.attributionUrl != null)
                    Wrap(
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () =>
                              launchUrl(Uri.parse(video.attributionUrl!)),
                          child: Text(switch (video.source) {
                            VideoSource.peertube => 'Autor · PeerTube ↗',
                            VideoSource.internetArchive =>
                              'Autor · Internet Archive ↗',
                            VideoSource.pexels => 'Autor · Pexels ↗',
                            VideoSource.pixabay => 'Autor · Pixabay ↗',
                            VideoSource.wikimedia =>
                              'Autor · Wikimedia Commons ↗',
                            _ => 'Autor ↗',
                          }, style: const TextStyle(fontSize: 12)),
                        ),
                        if (video.licenseUrl != null)
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () =>
                                launchUrl(Uri.parse(video.licenseUrl!)),
                            child: const Text(
                              'Licencia ↗',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  if (video.description.isNotEmpty)
                    Text(
                      video.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (video.description.isNotEmpty) const SizedBox(height: 4),
                  VideoDescription(
                    key: ValueKey(video.id),
                    text: video.description.isEmpty
                        ? video.caption
                        : video.description,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: MediaQuery.paddingOf(context).bottom + 20,
              right: 20,
              child: VideoButtons(video: video),
            ),
          ],
        );
      },
    );
  }
}
