import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'config/theme/app_theme.dart';
import 'infrastructure/datasources/peertube_video_datasource.dart';
import 'infrastructure/datasources/internet_archive_video_datasource.dart';
import 'infrastructure/datasources/wikimedia_video_datasource.dart';
import 'domain/services/seasonal_audio_policy.dart';
import 'domain/services/local_video_playback_service.dart';
import 'infrastructure/services/bundled_video_playback_service.dart';
import 'infrastructure/datasources/local_video_datasource_impl.dart';
import 'infrastructure/repositories/video_posts_repository_impl.dart';
import 'infrastructure/repositories/local_preferences_repository.dart';
import 'infrastructure/repositories/feed_repositories.dart';
import 'infrastructure/services/seasonal_audio.dart';
import 'infrastructure/services/platform_app_icon_service.dart';
import 'presentation/providers/preferences_provider.dart';
import 'presentation/screens/discover/discover_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final storage = await SharedPreferences.getInstance();
  runApp(MyApp(storage: storage));
}

class MyApp extends StatefulWidget {
  final SharedPreferences storage;
  const MyApp({super.key, required this.storage});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _client = http.Client();
  final _audio = SeasonalAudio();
  final _localPlayback = BundledVideoPlaybackService();
  final _appIcon = PlatformAppIconService();
  late final PreferencesProvider _preferences;
  late final DiscoverFeedRepository _discover;
  late final ForYouFeedRepository _forYou;
  late final FavoritesFeedRepository _favorites;
  Timer? _dateTimer;
  final _seasonalAudioPolicy = SeasonalAudioPolicy();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final preferences = LocalPreferencesRepository(widget.storage);
    _preferences = PreferencesProvider(preferences)
      ..addListener(_onPreferences);
    _discover = DiscoverFeedRepository({
      'PeerTube': VideoPostsRepositoryImpl(
        videosDatasource: PeerTubeVideoDatasource(_client, widget.storage),
      ),
      'Internet Archive': VideoPostsRepositoryImpl(
        videosDatasource: InternetArchiveVideoDatasource(
          _client,
          widget.storage,
        ),
      ),
      'Wikimedia Commons': VideoPostsRepositoryImpl(
        videosDatasource: WikimediaVideoDatasource(
          _client,
          widget.storage,
          sendUserAgent: !kIsWeb,
          preferQuickTime:
              !kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS),
        ),
      ),
    });
    _forYou = ForYouFeedRepository(
      VideoPostsRepositoryImpl(videosDatasource: LocalVideoDatasource()),
    );
    _favorites = FavoritesFeedRepository(preferences);
    _dateTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _preferences.refreshDate(),
    );
    _onPreferences();
  }

  void _onPreferences() {
    final season = _preferences.season;
    final muted = _preferences.repository.muted;
    _appIcon.applySeason(season).catchError((Object error) {
      debugPrint('No se pudo actualizar el icono de la app: $error');
    });
    if (_seasonalAudioPolicy.shouldPlay(
      season,
      muted: muted,
      enabled: _preferences.repository.seasonalAudio,
    )) {
      _audio
          .play(SeasonStyle.forSeason(season).melody)
          .catchError((Object _) {});
    } else if (muted || !_preferences.repository.seasonalAudio) {
      _audio.stop().catchError((Object _) {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _preferences.refreshDate();
    } else {
      _audio.stop().catchError((Object _) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dateTimer?.cancel();
    _preferences.removeListener(_onPreferences);
    _preferences.dispose();
    _client.close();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Provider<LocalVideoPlaybackService>.value(
        value: _localPlayback,
        child: ChangeNotifierProvider.value(
          value: _preferences,
          child: Consumer<PreferencesProvider>(
            builder: (context, preferences, _) => MaterialApp(
              title: 'Vdry',
              debugShowCheckedModeBanner: false,
              theme: AppTheme(season: preferences.season).getTheme(),
              home: DiscoverScreen(
                repositories: [_discover, _forYou, _favorites],
              ),
            ),
          ),
        ),
      );
}
