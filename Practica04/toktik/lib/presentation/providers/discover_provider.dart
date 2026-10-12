import 'package:flutter/material.dart';

import '../../domain/entities/video_post.dart';
import '../../domain/repositories/feed_repository.dart';

class DiscoverProvider extends ChangeNotifier {
  final FeedRepository repository;
  bool initialLoading = true;
  bool loading = false;
  bool hasMore = true;
  bool _disposed = false;
  int _page = 1;
  List<VideoPost> videos = [];
  List<String> unavailableSources = [];
  String? error;
  DiscoverProvider({required this.repository});
  Future<void> loadNextPage() async {
    if (loading || !hasMore) return;
    loading = true;
    if (!_disposed) notifyListeners();
    try {
      FeedPage result;
      if (repository is ProgressiveFeedRepository) {
        result = const FeedPage([], []);
        await for (final update
            in (repository as ProgressiveFeedRepository).loadProgressively(
              _page,
            )) {
          if (_disposed) return;
          result = update;
          final ids = videos.map((v) => v.id).toSet();
          videos.addAll(update.videos.where((v) => ids.add(v.id)));
          if (videos.isNotEmpty) initialLoading = false;
          notifyListeners();
        }
      } else {
        result = await repository.load(_page);
      }
      if (_disposed) return;
      unavailableSources = result.unavailableSources;
      final ids = videos.map((v) => v.id).toSet();
      videos.addAll(result.videos.where((v) => ids.add(v.id)));
      // No avanzar si la página falla por completo: permitir reintentar.
      if (result.videos.isEmpty && result.unavailableSources.isNotEmpty) {
        error = 'No se pudieron cargar los videos. Reintenta.';
      } else {
        error = null;
        hasMore = result.videos.isNotEmpty;
        _page++;
      }
    } catch (_) {
      if (!_disposed) error = 'No se pudieron cargar los videos.';
    } finally {
      if (!_disposed) {
        loading = false;
        initialLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
