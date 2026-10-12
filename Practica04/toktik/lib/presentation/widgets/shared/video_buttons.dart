import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/helpers/human_formats.dart';
import '../../../domain/entities/video_post.dart';
import '../../providers/preferences_provider.dart';

class VideoButtons extends StatelessWidget {
  final VideoPost video;
  const VideoButtons({super.key, required this.video});
  Future<void> _save(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar el cambio. Inténtalo de nuevo.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    final liked = prefs.repository.isLiked(video);
    final muted = prefs.repository.muted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: liked
              ? 'Quitar de favoritos'
              : 'Me gusta y guardar en favoritos',
          onPressed: () => _save(context, () => prefs.toggleLike(video)),
          icon: Icon(
            liked ? Icons.favorite : Icons.favorite_border,
            size: 34,
            color: liked ? Theme.of(context).colorScheme.primary : Colors.white,
          ),
        ),
        Text(
          HumanFormats.humanReadbleNumber(
            prefs.repository.likes(video).toDouble(),
          ),
        ),
        const SizedBox(height: 16),
        const Icon(Icons.visibility_outlined, color: Colors.white),
        Text(HumanFormats.humanReadbleNumber(video.views.toDouble())),
        const SizedBox(height: 16),
        IconButton(
          tooltip: muted ? 'Activar sonido' : 'Silenciar',
          onPressed: () => _save(context, prefs.toggleMuted),
          icon: Icon(
            muted ? Icons.volume_off : Icons.volume_up,
            color: Colors.white,
            size: 32,
          ),
        ),
      ],
    );
  }
}
