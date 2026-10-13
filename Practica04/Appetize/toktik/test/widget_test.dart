import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toktik/domain/entities/video_post.dart';
import 'package:toktik/domain/services/local_video_playback_service.dart';
import 'package:toktik/infrastructure/services/bundled_video_playback_service.dart';
import 'package:toktik/infrastructure/repositories/local_preferences_repository.dart';
import 'package:toktik/presentation/providers/preferences_provider.dart';
import 'package:toktik/presentation/widgets/shared/video_buttons.dart';
import 'package:toktik/presentation/widgets/settings/season_settings.dart';
import 'package:toktik/domain/entities/season.dart';
import 'package:toktik/presentation/widgets/video/video_description.dart';
import 'package:toktik/presentation/widgets/shared/video_scrollable_view.dart';
import 'package:toktik/presentation/screens/discover/discover_screen.dart';
import 'package:toktik/presentation/widgets/shared/season_splash.dart';
import 'package:toktik/domain/repositories/feed_repository.dart';
import 'package:toktik/config/theme/season_icons.dart';
import 'package:toktik/presentation/widgets/video/fullscreen_player.dart';
import 'package:toktik/presentation/widgets/video/remote_video_preloader.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  testWidgets('Botones actualizan likes y sonido persistentes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await SharedPreferences.getInstance();
    final preferences = PreferencesProvider(
      LocalPreferencesRepository(storage),
    );
    await preferences.repository.setMuted(true);
    const video = VideoPost(
      caption: 'Prueba',
      videoUrl: 'assets/videos/1.mp4',
      likes: 10,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: preferences,
        child: const MaterialApp(
          home: Scaffold(body: VideoButtons(video: video)),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(preferences.repository.likes(video), 11);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();
    expect(preferences.repository.likes(video), 10);
    await tester.tap(find.byIcon(Icons.volume_off));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.volume_up), findsOneWidget);
    expect(LocalPreferencesRepository(storage).muted, false);
  });
  testWidgets('Selector fuerza temporada y vuelve al modo automático', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await SharedPreferences.getInstance();
    final preferences = PreferencesProvider(
      LocalPreferencesRepository(storage),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: preferences,
        child: const MaterialApp(home: Scaffold(body: SeasonSettings())),
      ),
    );
    await tester.tap(find.text('Navidad'));
    await tester.pumpAndSettle();
    expect(
      LocalPreferencesRepository(storage).seasonOverride,
      Season.christmas,
    );
    await tester.tap(find.text('Automático (fecha del dispositivo)'));
    await tester.pumpAndSettle();
    expect(LocalPreferencesRepository(storage).seasonOverride, isNull);
  });
  testWidgets('Descripción larga se expande y permite desplazarse', (
    tester,
  ) async {
    final text = List.filled(
      50,
      'Una descripción extensa del video.',
    ).join(' ');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 250, child: VideoDescription(text: text)),
        ),
      ),
    );
    expect(find.text('... más'), findsOneWidget);
    await tester.tap(find.text('... más'));
    await tester.pump();
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('menos'), findsOneWidget);
    await tester.tap(find.text('menos'));
    await tester.pump();
    expect(find.byType(SingleChildScrollView), findsNothing);
  });
  testWidgets('Descripción breve se muestra sin botón más', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: VideoDescription(text: 'Hola')),
      ),
    );
    expect(find.text('... más'), findsNothing);
  });
  testWidgets(
    'Swipe vertical cambia video y la descripción tiene scroll independiente',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = PreferencesProvider(
        LocalPreferencesRepository(await SharedPreferences.getInstance()),
      );
      addTearDown(preferences.dispose);
      final text = List.filled(
        80,
        'Descripción extensa para probar el desplazamiento vertical.',
      ).join(' ');
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: preferences,
          child: MaterialApp(
            home: Scaffold(
              body: VideoScrollableView(
                active: false,
                videos: [
                  VideoPost(
                    caption: 'Primero',
                    videoUrl: '1',
                    description: text,
                  ),
                  const VideoPost(
                    caption: 'Segundo',
                    videoUrl: '2',
                    description: 'Descripción breve.',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('... más'));
      await tester.pumpAndSettle();
      final description = find.byType(SingleChildScrollView);
      final scroll = tester
          .widget<SingleChildScrollView>(description)
          .controller!;
      await tester.drag(description, const Offset(0, -140));
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(0));
      expect(find.text('Primero').hitTestable(), findsOneWidget);
      await tester.tap(find.text('menos'));
      await tester.pumpAndSettle();
      await tester.dragFrom(const Offset(300, 200), const Offset(0, -450));
      await tester.pumpAndSettle();
      expect(find.text('Segundo').hitTestable(), findsOneWidget);
      expect(find.text('Segundo'), findsOneWidget);
      await tester.dragFrom(const Offset(300, 200), const Offset(0, 450));
      await tester.pumpAndSettle();
      expect(find.text('Primero').hitTestable(), findsOneWidget);
    },
  );

  testWidgets('Para ti sigue accesible mientras Descubrir espera la red', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = PreferencesProvider(
      LocalPreferencesRepository(await SharedPreferences.getInstance()),
    );
    addTearDown(preferences.dispose);
    final waiting = _WaitingFeed();
    final local = _EmptyFeed();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: preferences,
        child: MaterialApp(
          home: DiscoverScreen(
            repositories: [waiting, local, _EmptyFavorites()],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Para ti'), findsOneWidget);
    await tester.tap(find.text('Para ti'));
    await tester.pump(const Duration(seconds: 1));
    expect(local.calls, 1);
    waiting.response.complete(FeedPage([], []));
    await tester.pumpAndSettle();
  });

  testWidgets('Swipe lateral cambia sección y carga su repository', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = PreferencesProvider(
      LocalPreferencesRepository(await SharedPreferences.getInstance()),
    );
    addTearDown(preferences.dispose);
    final discover = _EmptyFeed();
    final forYou = _EmptyFeed();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: preferences,
        child: MaterialApp(
          home: DiscoverScreen(
            repositories: [discover, forYou, _EmptyFavorites()],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Descubrir'), findsOneWidget);
    expect(find.text('Para ti'), findsOneWidget);
    expect(find.text('Favoritos'), findsOneWidget);
    final themes = find.byTooltip('Cambiar tema');
    expect(themes, findsOneWidget);
    expect(
      (tester.getCenter(themes).dy - tester.getCenter(find.byType(TabBar)).dy)
          .abs(),
      lessThan(1),
    );
    expect(discover.calls, 1);
    expect(forYou.calls, 0);
    await tester.drag(find.byType(TabBarView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(forYou.calls, 1);
    await tester.drag(find.byType(TabBarView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(
      find.text('Marca un corazón para guardar tus favoritos.'),
      findsOneWidget,
    );
  });

  test(
    'Precarga solo actual y siguiente, sin audio y reutiliza al avanzar',
    () async {
      final original = VideoPlayerPlatform.instance;
      final platform = _PreloadPlatform();
      VideoPlayerPlatform.instance = platform;
      addTearDown(() => VideoPlayerPlatform.instance = original);
      final pool = RemoteVideoPreloader();
      final videos = [
        for (var i = 1; i <= 3; i++)
          VideoPost(
            caption: 'Remoto $i',
            videoUrl: 'https://cdn.test/$i.mp4',
            source: VideoSource.peertube,
          ),
      ];
      pool.retain(videos);
      final first = pool.forVideo(videos[0])!;
      final next = pool.forVideo(videos[1])!;
      await first.ready;
      await next.ready;
      expect(platform.created, 2);
      expect(platform.playCalls, 0);
      expect(pool.forVideo(videos[2]), isNull);
      expect(next.controller.value.volume, 0);
      pool.retain(videos.skip(1));
      expect(identical(pool.forVideo(videos[1]), next), true);
      await pool.forVideo(videos[2])!.ready;
      expect(platform.created, 3);
      await pool.dispose();
      expect(platform.disposed.length, 3);
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  testWidgets('Mute y unmute solo cambian volumen, incluso al refrescar', (
    tester,
  ) async {
    final original = VideoPlayerPlatform.instance;
    final platform = _FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;
    addTearDown(() => VideoPlayerPlatform.instance = original);
    Widget surface(bool muted) => MaterialApp(
      home: Scaffold(
        body: FullScreenPlayer(
          video: const VideoPost(
            caption: 'Local',
            videoUrl: 'assets/videos/1.mp4',
          ),
          muted: muted,
        ),
      ),
    );
    await tester.pumpWidget(surface(false));
    await tester.pumpAndSettle();
    final initialPlayCalls = platform.playCalls;
    final initialPauseCalls = platform.pauseCalls;
    await tester.pumpWidget(surface(true));
    await tester.pumpAndSettle();
    expect(platform.volume, 0);
    await tester.pumpWidget(surface(false));
    await tester.pumpAndSettle();
    expect(platform.volume, 1);
    expect(platform.playing, true);
    expect(platform.playCalls, initialPlayCalls);
    expect(platform.pauseCalls, initialPauseCalls);
    await tester.pumpWidget(surface(false));
    await tester.pump(const Duration(minutes: 1));
    expect(platform.playCalls, initialPlayCalls);
    expect(platform.pauseCalls, initialPauseCalls);
    await tester.tap(find.byType(FullScreenPlayer));
    await tester.pumpAndSettle();
    expect(platform.playing, false);
    await tester.pumpWidget(surface(true));
    await tester.pumpAndSettle();
    await tester.pumpWidget(surface(false));
    await tester.pumpAndSettle();
    expect(platform.playing, false);
    expect(platform.playCalls, initialPlayCalls);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'Toque pausa y reanuda fuentes externas sin que mute revierta la pausa',
    (tester) async {
      final original = VideoPlayerPlatform.instance;
      final platform = _FakeVideoPlatform();
      VideoPlayerPlatform.instance = platform;
      addTearDown(() => VideoPlayerPlatform.instance = original);
      for (final source in [
        VideoSource.pexels,
        VideoSource.pixabay,
        VideoSource.wikimedia,
      ]) {
        final video = VideoPost(
          caption: 'Video',
          videoUrl: 'https://example.com/video',
          source: source,
          externalId: 'demo',
        );
        Widget surface(bool muted) => MaterialApp(
          home: Scaffold(
            body: FullScreenPlayer(
              key: ValueKey(source),
              video: video,
              muted: muted,
            ),
          ),
        );
        await tester.pumpWidget(surface(true));
        await tester.pumpAndSettle();
        expect(platform.dataSource!.sourceType, DataSourceType.network);
        expect(platform.dataSource!.uri, video.videoUrl);
        expect(platform.playing, true);
        await tester.tap(find.byType(FullScreenPlayer));
        await tester.pumpAndSettle();
        expect(platform.playing, false);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        await tester.pumpWidget(surface(false));
        await tester.pumpAndSettle();
        expect(platform.playing, false);
        expect(platform.volume, 1);
        await tester.tap(find.byType(FullScreenPlayer));
        await tester.pumpAndSettle();
        expect(platform.playing, true);
        expect(find.byIcon(Icons.play_arrow), findsNothing);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'Reproduce variante local compatible sin perder identidad ni audio',
    (tester) async {
      final original = VideoPlayerPlatform.instance;
      final platform = _FakeVideoPlatform();
      VideoPlayerPlatform.instance = platform;
      addTearDown(() => VideoPlayerPlatform.instance = original);
      const video = VideoPost(
        caption: 'Escaleras',
        videoUrl: 'assets/videos/1.mp4',
      );
      await tester.pumpWidget(
        Provider<LocalVideoPlaybackService>(
          create: (_) => BundledVideoPlaybackService(
            assetPaths: () async => {
              'assets/videos/1.mp4',
              'assets/videos/playback/1.mp4',
            },
          ),
          child: const MaterialApp(
            home: Scaffold(body: FullScreenPlayer(video: video)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(platform.dataSource!.sourceType, DataSourceType.asset);
      expect(platform.dataSource!.asset, 'assets/videos/playback/1.mp4');
      expect(video.id, 'local:assets/videos/1.mp4');
      expect(platform.volume, 1);
      expect(platform.playing, true);
      await tester.tap(find.byType(FullScreenPlayer));
      await tester.pumpAndSettle();
      expect(platform.playing, false);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Splash muestra el icono de la temporada persistida', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalPreferencesRepository(
      await SharedPreferences.getInstance(),
    );
    await repository.setSeason(Season.valentines);
    final preferences = PreferencesProvider(
      LocalPreferencesRepository(repository.storage),
    );
    addTearDown(preferences.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: preferences,
        child: const MaterialApp(home: Scaffold(body: SeasonSplash())),
      ),
    );
    await tester.pump();
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      SeasonIcons.assetFor(Season.valentines),
    );
    expect(find.text('Vdry · San Valentín'), findsOneWidget);
  });
}

class _EmptyFeed implements FeedRepository {
  int calls = 0;
  @override
  Future<FeedPage> load(int page) async {
    calls++;
    return const FeedPage([], []);
  }
}

class _EmptyFavorites implements FavoritesRepository {
  @override
  List<VideoPost> get savedVideos => [];
  @override
  Future<FeedPage> load(int page) async => const FeedPage([], []);
}

class _FakeVideoPlatform extends VideoPlayerPlatform {
  DataSource? dataSource;
  bool playing = false;
  int playCalls = 0;
  int pauseCalls = 0;
  double volume = 0;
  @override
  Future<void> init() async {}
  @override
  Future<int> createWithOptions(VideoCreationOptions options) async {
    dataSource = options.dataSource;
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 30),
      size: const Size(720, 1280),
    ),
  );
  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const ColoredBox(color: Colors.black);
  @override
  Future<void> dispose(int playerId) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> play(int playerId) async {
    playCalls++;
    playing = true;
  }

  @override
  Future<void> pause(int playerId) async {
    pauseCalls++;
    playing = false;
  }

  @override
  Future<void> setVolume(int playerId, double value) async {
    volume = value;
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
}

class _WaitingFeed implements FeedRepository {
  final response = Completer<FeedPage>();
  @override
  Future<FeedPage> load(int page) => response.future;
}

class _PreloadPlatform extends _FakeVideoPlatform {
  int created = 0;
  final disposed = <int>[];
  @override
  Future<int> createWithOptions(VideoCreationOptions options) async =>
      ++created;
  @override
  Future<void> dispose(int playerId) async {
    disposed.add(playerId);
  }
}
