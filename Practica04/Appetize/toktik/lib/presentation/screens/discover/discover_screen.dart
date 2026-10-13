import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/repositories/feed_repository.dart';
import '../../providers/discover_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../widgets/settings/season_settings.dart';
import '../../widgets/shared/video_scrollable_view.dart';
import '../../widgets/shared/season_splash.dart';

class DiscoverScreen extends StatefulWidget {
  final List<FeedRepository> repositories;
  const DiscoverScreen({super.key, required this.repositories});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final List<DiscoverProvider> _feeds;
  int _tab = 0;
  bool _settingsOpen = false;
  @override
  void initState() {
    super.initState();
    _feeds = widget.repositories
        .map((r) => DiscoverProvider(repository: r))
        .toList();
    _tabs = TabController(length: 3, vsync: this)..addListener(_selectTab);
    _feeds.first.loadNextPage();
  }

  void _selectTab() {
    final index = _tabs.index;
    if (_tab == index) return;
    setState(() => _tab = index);
    if (index < 2 && _feeds[index].initialLoading) {
      _feeds[index].loadNextPage();
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_selectTab);
    _tabs.dispose();
    for (final feed in _feeds) {
      feed.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildContent(context);

  Widget _buildContent(BuildContext context) {
    context.watch<PreferencesProvider>();
    final favorites =
        (widget.repositories[2] as FavoritesRepository).savedVideos;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          TabBarView(
            controller: _tabs,
            children: [
              _feedView(0),
              _feedView(1),
              favorites.isEmpty
                  ? const Center(
                      child: Text(
                        'Marca un corazón para guardar tus favoritos.',
                      ),
                    )
                  : VideoScrollableView(
                      key: const ValueKey('favorites'),
                      videos: favorites,
                      active: _tab == 2 && !_settingsOpen,
                    ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          controller: _tabs,
                          dividerColor: Colors.transparent,
                          labelPadding: EdgeInsets.zero,
                          unselectedLabelColor: Colors.white70,
                          labelColor: Theme.of(context).colorScheme.primary,
                          tabs: const [
                            Tab(text: 'Descubrir'),
                            Tab(text: 'Para ti'),
                            Tab(text: 'Favoritos'),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cambiar tema',
                        icon: const Icon(
                          Icons.palette_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          setState(() => _settingsOpen = true);
                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => const SeasonSettings(),
                          );
                          if (mounted) setState(() => _settingsOpen = false);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedView(int index) => ListenableBuilder(
    listenable: _feeds[index],
    builder: (context, _) {
      final feed = _feeds[index];
      if (feed.initialLoading) return const SeasonSplash();
      if (feed.videos.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(feed.error ?? 'No hay videos disponibles.'),
              TextButton(
                onPressed: feed.loadNextPage,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          VideoScrollableView(
            key: ValueKey(index),
            videos: feed.videos,
            active: _tab == index && !_settingsOpen,
            onNearEnd: feed.loadNextPage,
          ),
          if (feed.loading)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      );
    },
  );
}
