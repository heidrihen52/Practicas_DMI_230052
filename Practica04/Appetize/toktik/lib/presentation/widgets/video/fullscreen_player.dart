import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../domain/entities/video_post.dart';
import '../../../domain/services/local_video_playback_service.dart';
import 'remote_video_preloader.dart';

class FullScreenPlayer extends StatefulWidget {
  final VideoPost video;
  final bool muted;
  final bool active;
  final PreparedRemoteVideo? prepared;
  const FullScreenPlayer({
    super.key,
    required this.video,
    this.muted = false,
    this.active = true,
    this.prepared,
  });
  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  late Future<void> _initialization;
  bool _foreground = true;
  bool _paused = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.video.supportsDirectPlayback) {
      _initialization = _initialize();
    }
  }

  Future<void> _initialize() async {
    if (widget.prepared != null) {
      _controller = widget.prepared!.controller;
      await widget.prepared!.ready;
      if (mounted) await _sync();
      return;
    }
    final local = widget.video.source == VideoSource.local;
    final resolver = local ? context.read<LocalVideoPlaybackService?>() : null;
    final path = resolver == null
        ? widget.video.videoUrl
        : await resolver.resolve(widget.video.videoUrl);
    if (!mounted) return;
    _controller = local
        ? VideoPlayerController.asset(path)
        : VideoPlayerController.networkUrl(Uri.parse(path));
    await _controller!.initialize();
    if (!mounted) return;
    await _controller!.setLooping(true);
    await _sync();
  }

  Future<void> _syncVolume() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.setVolume(widget.muted ? 0 : 1);
  }

  Future<void> _syncPlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final shouldPlay = widget.active && _foreground && !_paused;
    if (shouldPlay == controller.value.isPlaying) return;
    if (shouldPlay) {
      await controller.play();
    } else {
      await controller.pause();
    }
  }

  Future<void> _sync() async {
    await _syncVolume();
    if (mounted) await _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant FullScreenPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.muted != widget.muted) _syncVolume();
    if (oldWidget.active != widget.active) _syncPlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    setState(() => _foreground = state == AppLifecycleState.resumed);
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.prepared == null) _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() => _paused = !_paused);
    _syncPlayback();
  }

  Widget _playbackSurface(Widget child) => Semantics(
    button: true,
    label: _paused ? 'Reproducir video' : 'Pausar video',
    onTap: _togglePlayback,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: _togglePlayback,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          IgnorePointer(child: child),
          if (_paused)
            const Center(
              child: Icon(Icons.play_arrow, color: Colors.white, size: 72),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.video.supportsDirectPlayback) {
      return const Center(
        child: Text('Esta fuente anterior ya no está disponible.'),
      );
    }
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('No se pudo reproducir este video.'));
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return _playbackSurface(
          SizedBox.expand(
            child: FittedBox(
              fit: widget.video.source == VideoSource.local
                  ? BoxFit.cover
                  : BoxFit.contain,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
        );
      },
    );
  }
}
