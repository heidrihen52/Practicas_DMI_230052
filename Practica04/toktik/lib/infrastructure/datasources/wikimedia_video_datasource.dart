import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/video_post.dart';
import 'direct_video_datasource.dart';

/// Videos públicos de naturaleza con pista de audio original. Sin API key.
class WikimediaVideoDatasource extends DirectVideoDatasource {
  static const query =
      'filetype:video (waterfall OR forest OR landscape OR walking OR beach OR flowers)';
  final Map<int, List<VideoPost>> _pages = {};
  int _offset = 0;
  bool _exhausted = false;
  final bool preferQuickTime;
  final bool sendUserAgent;
  WikimediaVideoDatasource(
    http.Client client,
    SharedPreferences storage, {
    this.preferQuickTime = false,
    this.sendUserAgent = true,
  }) : super(client, storage, 'wikimedia.nature.v1');

  @override
  Future<List<VideoPost>> getTrendingVideosByPage(int page) async {
    if (page < 1) return [];
    for (var logical = 1; logical <= page; logical++) {
      if (_pages.containsKey(logical)) continue;
      if (_exhausted) return [];
      final videos = <VideoPost>[];
      while (videos.isEmpty && !_exhausted) {
        final data = await getJson(
          Uri.https('commons.wikimedia.org', '/w/api.php', {
            'action': 'query',
            'format': 'json',
            'origin': '*',
            'generator': 'search',
            'gsrsearch': query,
            'gsrnamespace': '6',
            'gsrlimit': '40',
            'gsroffset': '$_offset',
            'prop': 'videoinfo',
            'viprop': 'url|size|metadata|extmetadata|derivatives',
            'viextmetadatalanguage': 'es',
            'viextmetadatafilter':
                'Artist|ImageDescription|LicenseShortName|LicenseUrl',
          }),
          'offset.$_offset',
          headers: {
            'Api-User-Agent':
                'Vdry/1.0 (Flutter academic project; adrian230052)',
            if (sendUserAgent)
              'User-Agent': 'Vdry/1.0 (Flutter academic project; adrian230052)',
          },
        );
        if (data['error'] != null) {
          throw StateError('Wikimedia: no se pudo consultar el catálogo');
        }
        final pages =
            (data['query']?['pages'] as Map<String, dynamic>? ?? {}).values
                .cast<Map<String, dynamic>>()
                .toList()
              ..sort(
                (a, b) =>
                    DirectVideoDatasource.number(a['index'])
                        .compareTo(DirectVideoDatasource.number(b['index'])),
              );
        for (final item in pages) {
          if (!RegExp(
            r'waterfall|forest|landscape|walk|beach|flower',
            caseSensitive: false,
          ).hasMatch('${item['title']}')) {
            continue;
          }
          final info = (item['videoinfo'] as List? ?? []).firstOrNull;
          if (info == null) continue;
          final width = DirectVideoDatasource.number(info['width']);
          final height = DirectVideoDatasource.number(info['height']);
          final duration = num.tryParse('${info['duration']}') ?? 0;
          final hasAudio = (info['metadata'] as List? ?? []).any(
            (entry) =>
                entry['name'] == 'audio' &&
                (entry['value'] as List? ?? []).isNotEmpty,
          );
          if (width <= 0 ||
              height / width < 1.4 ||
              duration <= 0 ||
              duration > 90 ||
              !hasAudio) {
            continue;
          }
          final files =
              (info['derivatives'] as List? ?? [])
                  .cast<Map<String, dynamic>>()
                  .where((file) {
                    final uri = Uri.tryParse('${file['src']}');
                    final type = '${file['type']}';
                    return uri?.scheme == 'https' &&
                        uri?.host == 'upload.wikimedia.org' &&
                        DirectVideoDatasource.number(file['height']) >
                            DirectVideoDatasource.number(file['width']) &&
                        (preferQuickTime
                            ? type.startsWith('video/quicktime')
                            : type.startsWith('video/webm') &&
                                  (type.contains('opus') ||
                                      type.contains('vorbis')));
                  })
                  .toList()
                ..sort(
                  (a, b) => (DirectVideoDatasource.number(a['height']) - 480)
                      .abs()
                      .compareTo(
                        (DirectVideoDatasource.number(b['height']) - 480).abs(),
                      ),
                );
          if (files.isEmpty) continue;
          final metadata = info['extmetadata'] as Map<String, dynamic>? ?? {};
          String meta(String key) =>
              plainText('${metadata[key]?['value'] ?? ''}');
          final title = '${item['title']}'
              .replaceFirst('File:', '')
              .replaceFirst(RegExp(r'\.[^.]+$'), '');
          videos.add(
            VideoPost(
              caption: title,
              videoUrl: files.first['src'] as String,
              source: VideoSource.wikimedia,
              externalId: '${item['pageid']}',
              attributionUrl: info['descriptionurl'] as String?,
              licenseUrl: metadata['LicenseUrl']?['value'] as String?,
              description:
                  '${meta('ImageDescription')}\n'
                  'Autor: ${meta('Artist')} · Wikimedia Commons · ${meta('LicenseShortName')}. '
                  'Se conserva el encuadre original.',
            ),
          );
        }
        final next = data['continue']?['gsroffset'];
        _exhausted =
            next == null || DirectVideoDatasource.number(next) <= _offset;
        if (!_exhausted) _offset = DirectVideoDatasource.number(next);
      }
      _pages[logical] = videos;
    }
    return _pages[page] ?? [];
  }

  static String plainText(String text) => text
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
