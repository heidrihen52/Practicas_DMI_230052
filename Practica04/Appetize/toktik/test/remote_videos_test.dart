import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toktik/domain/entities/video_post.dart';
import 'package:toktik/domain/repositories/video_posts_repository.dart';
import 'package:toktik/presentation/providers/discover_provider.dart';
import 'package:toktik/infrastructure/datasources/local_video_datasource_impl.dart';
import 'package:toktik/infrastructure/datasources/peertube_video_datasource.dart';
import 'package:toktik/infrastructure/datasources/internet_archive_video_datasource.dart';
import 'package:toktik/infrastructure/datasources/wikimedia_video_datasource.dart';
import 'package:toktik/infrastructure/repositories/feed_repositories.dart';
import 'package:toktik/infrastructure/repositories/video_posts_repository_impl.dart';

Map<String, dynamic> clip(
  int id, {
  int width = 720,
  int height = 1280,
  bool audio = true,
  int duration = 20,
  String name = 'Forest',
}) => {
  'pageid': id,
  'index': id,
  'title': 'File:$name $id.webm',
  'videoinfo': [
    {
      'width': width,
      'height': height,
      'duration': duration,
      'descriptionurl':
          'https://commons.wikimedia.org/wiki/File:Forest_$id.webm',
      'metadata': [
        if (audio)
          {
            'name': 'audio',
            'value': [
              {'name': 'channels', 'value': 2},
            ],
          },
      ],
      'derivatives': [
        {
          'src': 'https://upload.wikimedia.org/forest$id.webm',
          'type': 'video/webm; codecs="vp9, opus"',
          'width': width,
          'height': height,
        },
        {
          'src': 'https://upload.wikimedia.org/forest$id.mov',
          'type': 'video/quicktime; codecs="mp4v"',
          'width': 202,
          'height': 360,
        },
      ],
      'extmetadata': {
        'Artist': {'value': '<a>Autor $id</a>'},
        'ImageDescription': {'value': 'Un bosque &amp; naturaleza'},
        'LicenseShortName': {'value': 'CC BY-SA 4.0'},
        'LicenseUrl': {
          'value': 'https://creativecommons.org/licenses/by-sa/4.0/',
        },
      },
    },
  ],
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences storage;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await SharedPreferences.getInstance();
  });
  test(
    'Wikimedia pagina más de seis clips, sin claves ni tutoriales',
    () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        expect(request.url.host, 'commons.wikimedia.org');
        expect(request.url.queryParameters['prop'], 'videoinfo');
        expect(request.headers['Api-User-Agent'], contains('adrian230052'));
        expect(request.headers.containsKey('Authorization'), false);
        final offset = int.parse(request.url.queryParameters['gsroffset']!);
        return http.Response(
          jsonEncode({
            'query': {
              'pages': {'${offset + 1}': clip(offset + 1)},
            },
            if (offset < 280) 'continue': {'gsroffset': offset + 40},
          }),
          200,
        );
      });
      addTearDown(client.close);
      final source = WikimediaVideoDatasource(client, storage);
      final videos = <VideoPost>[];
      for (var page = 1; page <= 8; page++) {
        videos.addAll(await source.getTrendingVideosByPage(page));
      }
      expect(videos, hasLength(8));
      expect(videos.map((v) => v.id).toSet(), hasLength(8));
      expect(videos.every((v) => v.source == VideoSource.wikimedia), true);
      expect(videos.first.description, contains('Autor 1'));
      expect(videos.first.description, contains('bosque & naturaleza'));
      expect(videos.first.description, isNot(contains('<a>')));
      expect(await source.getTrendingVideosByPage(9), isEmpty);
      await source.getTrendingVideosByPage(1);
      expect(calls, 8);
      await WikimediaVideoDatasource(
        client,
        storage,
      ).getTrendingVideosByPage(1);
      expect(calls, 8);
    },
  );
  test(
    'Wikimedia omite horizontal, silencioso, largo y contenido ajeno',
    () async {
      final client = MockClient((request) async {
        final offset = int.parse(request.url.queryParameters['gsroffset']!);
        return http.Response(
          jsonEncode({
            'query': {
              'pages': offset == 0
                  ? {
                      '1': clip(1, width: 1280, height: 720),
                      '2': clip(2, audio: false),
                      '3': clip(3, duration: 200),
                      '4': clip(4, name: 'Tutorial'),
                    }
                  : {'5': clip(5)},
            },
            if (offset == 0) 'continue': {'gsroffset': 40},
          }),
          200,
        );
      });
      addTearDown(client.close);
      final source = WikimediaVideoDatasource(client, storage);
      expect(
        (await source.getTrendingVideosByPage(1)).single.id,
        'wikimedia:5',
      );
      expect(await source.getTrendingVideosByPage(2), isEmpty);
    },
  );
  test(
    'Variante QuickTime conserva formato nativo para plataformas Apple',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'query': {
              'pages': {'1': clip(1)},
            },
          }),
          200,
        ),
      );
      addTearDown(client.close);
      final source = WikimediaVideoDatasource(
        client,
        storage,
        preferQuickTime: true,
      );
      expect(
        (await source.getTrendingVideosByPage(1)).single.videoUrl,
        endsWith('.mov'),
      );
    },
  );
  test('Descubrir consulta tres APIs públicas sin claves', () async {
    final hosts = <String>{};
    final client = MockClient((request) async {
      hosts.add(request.url.host);
      expect(request.headers.containsKey('Authorization'), false);
      expect(request.url.queryParameters.containsKey('key'), false);
      if (request.url.host.endsWith('.archive.org')) {
        return http.Response.bytes([
          ...ascii.encode('hdlr'),
          ...List.filled(8, 0),
          ...ascii.encode('soun'),
        ], 206);
      }
      final data = switch (request.url.host) {
        'sepiasearch.org' => {
          'total': 1,
          'data': [peerSummary(1)],
        },
        'peer.test' => peerDetails(1),
        'archive.org' => archiveDetails(request.url.path.split('/').last),
        _ => {
          'query': {
            'pages': {'3': clip(3)},
          },
        },
      };
      return http.Response(jsonEncode(data), 200);
    });
    addTearDown(client.close);
    final discover = DiscoverFeedRepository({
      'PeerTube': VideoPostsRepositoryImpl(
        videosDatasource: PeerTubeVideoDatasource(client, storage),
      ),
      'Internet Archive': VideoPostsRepositoryImpl(
        videosDatasource: InternetArchiveVideoDatasource(client, storage),
      ),
      'Wikimedia': VideoPostsRepositoryImpl(
        videosDatasource: WikimediaVideoDatasource(client, storage),
      ),
    });
    final result = await discover.load(1);
    expect(
      hosts,
      containsAll({
        'sepiasearch.org',
        'peer.test',
        'archive.org',
        'commons.wikimedia.org',
      }),
    );
    expect(result.videos.map((v) => v.source), [
      VideoSource.peertube,
      VideoSource.internetArchive,
      VideoSource.wikimedia,
      VideoSource.internetArchive,
    ]);
    expect(result.unavailableSources, isEmpty);
  });
  test(
    'Resultados rápidos aparecen antes de terminar la fuente lenta',
    () async {
      final fast = _PendingPosts();
      final slow = _PendingPosts();
      final provider = DiscoverProvider(
        repository: DiscoverFeedRepository({'rápida': fast, 'lenta': slow}),
      );
      addTearDown(provider.dispose);
      final complete = provider.loadNextPage();
      fast.response.complete([
        const VideoPost(
          caption: 'Rápido',
          videoUrl: 'https://cdn.test/1.mp4',
          source: VideoSource.wikimedia,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.videos, hasLength(1));
      expect(provider.initialLoading, false);
      expect(provider.loading, true);
      slow.response.complete([
        const VideoPost(
          caption: 'Lento',
          videoUrl: 'https://cdn.test/2.mp4',
          source: VideoSource.internetArchive,
        ),
      ]);
      await complete;
      expect(provider.videos, hasLength(2));
      expect(provider.loading, false);
    },
  );
  test('PeerTube elige HLS ligero con sonido antes del MP4 pesado', () async {
    final client = MockClient((request) async {
      final data = request.url.host == 'sepiasearch.org'
          ? {
              'total': 1,
              'data': [peerSummary(1)],
            }
          : {
              ...peerDetails(1),
              'files': [
                {
                  'width': 1080,
                  'height': 1920,
                  'fileUrl': 'https://cdn.test/heavy.mp4',
                  'hasAudio': true,
                  'hasVideo': true,
                },
                {
                  'width': 360,
                  'height': 640,
                  'fileUrl': 'https://cdn.test/light.mp4',
                  'playlistUrl': 'https://cdn.test/light.m3u8',
                  'hasAudio': true,
                  'hasVideo': true,
                },
              ],
            };
      return http.Response(jsonEncode(data), 200);
    });
    addTearDown(client.close);
    expect(
      (await PeerTubeVideoDatasource(
        client,
        storage,
      ).getTrendingVideosByPage(1)).single.videoUrl,
      'https://cdn.test/light.m3u8',
    );
  });
  test('PeerTube omite horizontales, silenciosos y páginas vacías', () async {
    final client = MockClient((request) async {
      if (request.url.host == 'peer.test') {
        return http.Response(
          jsonEncode(peerDetails(int.parse(request.url.path.split('/').last))),
          200,
        );
      }
      final start = int.parse(request.url.queryParameters['start']!);
      return http.Response(
        jsonEncode({
          'total': 2,
          'data': [peerSummary(start + 1, ratio: start == 0 ? 1.7 : .5625)],
        }),
        200,
      );
    });
    addTearDown(client.close);
    final source = PeerTubeVideoDatasource(client, storage);
    expect(
      (await source.getTrendingVideosByPage(1)).single.id,
      'peertube:peer.test/2',
    );
    expect(await source.getTrendingVideosByPage(2), isEmpty);
    expect(
      VideoPost.fromJson(
        (await source.getTrendingVideosByPage(1)).single.toJson(),
      ).licenseUrl,
      isNotNull,
    );
  });
  test('PeerTube exige pista sonora y prefiere 720p', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode(
          request.url.host == 'sepiasearch.org'
              ? {
                  'total': 2,
                  'data': [peerSummary(1), peerSummary(2)],
                }
              : peerDetails(
                  int.parse(request.url.path.split('/').last),
                  audio: request.url.path.endsWith('/2'),
                ),
        ),
        200,
      ),
    );
    addTearDown(client.close);
    final videos = await PeerTubeVideoDatasource(
      client,
      storage,
    ).getTrendingVideosByPage(1);
    expect(videos, hasLength(1));
    expect(videos.single.videoUrl, 'https://cdn.test/2.mp4');
  });
  test('Archive pagina más de seis y descarta MP4 sin audio', () async {
    final client = MockClient((request) async {
      if (request.url.host.endsWith('.archive.org')) {
        final audible = !request.url.path.contains('silent');
        return http.Response.bytes(
          audible
              ? [
                  ...ascii.encode('hdlr'),
                  ...List.filled(8, 0),
                  ...ascii.encode('soun'),
                ]
              : List.filled(16, 0),
          206,
        );
      }
      if (request.url.path == '/advancedsearch.php') {
        final page = int.parse(request.url.queryParameters['page']!);
        return http.Response(
          jsonEncode({
            'response': {
              'numFound': 56,
              'docs': [
                {'identifier': 'waterfall$page'},
              ],
            },
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode(
          archiveDetails(
            request.url.path.split('/').last == 'img-9763_202610'
                ? 'silent'
                : request.url.path.split('/').last,
          ),
        ),
        200,
      );
    });
    addTearDown(client.close);
    final source = InternetArchiveVideoDatasource(client, storage);
    final videos = <VideoPost>[];
    for (var page = 1; page <= 8; page++) {
      videos.addAll(await source.getTrendingVideosByPage(page));
    }
    expect(videos, hasLength(8));
    expect(videos.map((v) => v.id).toSet(), hasLength(8));
    expect(await source.getTrendingVideosByPage(9), isEmpty);
    var calls = 0;
    final cached = MockClient((_) async {
      calls++;
      return http.Response('{}', 500);
    });
    addTearDown(cached.close);
    expect(
      await InternetArchiveVideoDatasource(
        cached,
        storage,
      ).getTrendingVideosByPage(1),
      hasLength(1),
    );
    expect(calls, 0);
  });
  test('Fallo de una API no bloquea las demás ni invade Para ti', () async {
    final client = MockClient(
      (request) async => request.url.host == 'sepiasearch.org'
          ? http.Response('error', 503)
          : http.Response(
              jsonEncode({
                'query': {
                  'pages': {'1': clip(1)},
                },
              }),
              200,
            ),
    );
    addTearDown(client.close);
    final page = await DiscoverFeedRepository({
      'PeerTube': VideoPostsRepositoryImpl(
        videosDatasource: PeerTubeVideoDatasource(client, storage),
      ),
      'Wikimedia': VideoPostsRepositoryImpl(
        videosDatasource: WikimediaVideoDatasource(client, storage),
      ),
    }).load(1);
    expect(page.videos.single.source, VideoSource.wikimedia);
    expect(page.unavailableSources, ['PeerTube']);
  });
  test(
    'Para ti conserva los 13 locales sin consultar la API de Descubrir',
    () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response(
          jsonEncode({
            'query': {
              'pages': {'1': clip(1)},
            },
          }),
          200,
        );
      });
      addTearDown(client.close);
      final discover = DiscoverFeedRepository({
        'Wikimedia Commons': VideoPostsRepositoryImpl(
          videosDatasource: WikimediaVideoDatasource(client, storage),
        ),
      });
      final forYou = ForYouFeedRepository(
        VideoPostsRepositoryImpl(
          videosDatasource: LocalVideoDatasource(
            assetPaths: () async => {
              for (var n = 1; n <= 13; n++) 'assets/videos/$n.mp4',
            },
          ),
        ),
      );
      final local = await forYou.load(1);
      expect(local.videos, hasLength(13));
      expect(local.videos.every((v) => v.source == VideoSource.local), true);
      expect(calls, 0);
      expect((await forYou.load(2)).videos, isEmpty);
      expect(
        (await discover.load(1)).videos.single.source,
        VideoSource.wikimedia,
      );
      expect(calls, 1);
      expect((await discover.load(2)).videos, isEmpty);
    },
  );
}

Map<String, dynamic> peerSummary(int id, {double ratio = .5625}) => {
  'uuid': '$id',
  'url': 'https://peer.test/videos/watch/$id',
  'name': 'Waterfall $id',
  'aspectRatio': ratio,
  'duration': 20,
  'licence': {'id': 1, 'label': 'Attribution'},
};
Map<String, dynamic> peerDetails(int id, {bool audio = true}) => {
  ...peerSummary(id),
  'account': {'displayName': 'Autor'},
  'files': [
    {
      'width': 720,
      'height': 1280,
      'fileUrl': 'https://cdn.test/$id.mp4',
      'hasAudio': audio,
      'hasVideo': true,
    },
  ],
};
Map<String, dynamic> archiveDetails(String id) => {
  'd1': 'ia800000.us.archive.org',
  'dir': '/0/items/$id',
  'metadata': {
    'title': 'Forest',
    'creator': 'Autor',
    'licenseurl': 'https://creativecommons.org/licenses/by/4.0/',
  },
  'files': [
    {
      'name': 'forest.mp4',
      'width': '720',
      'height': '1280',
      'length': '20',
      'size': '100000',
    },
  ],
};

class _PendingPosts implements VideoPostRepository {
  final response = Completer<List<VideoPost>>();
  @override
  Future<List<VideoPost>> getTrendingVideosByPage(int page) => response.future;
  @override
  Future<List<VideoPost>> getFavoriteVideosByUser(String userID) async => [];
}
