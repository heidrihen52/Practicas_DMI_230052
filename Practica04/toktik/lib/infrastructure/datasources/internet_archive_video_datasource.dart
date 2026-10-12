import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/video_post.dart';
import 'direct_video_datasource.dart';
import 'wikimedia_video_datasource.dart';

/// Metadatos y búsqueda públicos; MP4 directo con audio comprobado en su cabecera.
class InternetArchiveVideoDatasource extends DirectVideoDatasource {
  static const query = 'mediatype:movies AND title:waterfall AND licenseurl:*';
  final _pages = <int, List<VideoPost>>{};
  final _seen = <String>{};
  int _searchPage = 1;
  bool _seedLoaded = false;
  bool _exhausted = false;
  InternetArchiveVideoDatasource(http.Client client, SharedPreferences storage)
    : super(client, storage, 'archive.nature.v1');

  @override
  Future<List<VideoPost>> getTrendingVideosByPage(int page) async {
    if (page < 1) return [];
    for (var logical = 1; logical <= page; logical++) {
      if (_pages.containsKey(logical)) continue;
      final videos = <VideoPost>[];
      while (videos.isEmpty && !_exhausted) {
        List<String> identifiers;
        if (!_seedLoaded) {
          identifiers = ['Flickr-22002602029', 'img-9763_202610'];
        } else {
          final data = await getJson(
            Uri.https('archive.org', '/advancedsearch.php', {
              'q': query,
              'output': 'json',
              'fl[]': 'identifier',
              'rows': '8',
              'page': '$_searchPage',
              'sort[]': 'publicdate desc',
            }),
            'search.$_searchPage',
          );
          final response = data['response'] as Map<String, dynamic>?;
          if (response == null) {
            throw StateError('Internet Archive: catálogo no disponible');
          }
          identifiers = (response['docs'] as List? ?? [])
              .map((item) => '${item['identifier']}')
              .toList();
          _exhausted =
              identifiers.isEmpty ||
              _searchPage * 8 >=
                  DirectVideoDatasource.number(response['numFound']);
          _searchPage++;
        }
        var failures = 0;
        final batches = await Future.wait(
          identifiers.map((id) async {
            try {
              return await _resolve(id);
            } catch (_) {
              failures++;
              return <VideoPost>[];
            }
          }),
        );
        if (identifiers.isNotEmpty && failures == identifiers.length) {
          if (_seedLoaded) {
            _searchPage--;
            _exhausted = false;
          }
          throw StateError('Internet Archive: archivos no disponibles');
        }
        _seedLoaded = true;
        for (final video in batches.expand((batch) => batch)) {
          if (_seen.add(video.id)) videos.add(video);
        }
      }
      _pages[logical] = videos;
    }
    return _pages[page] ?? [];
  }

  Future<List<VideoPost>> _resolve(String id) async {
    final data = await getJson(
      Uri.https('archive.org', '/metadata/$id'),
      'item.$id',
    );
    final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
    final license = '${metadata['licenseurl'] ?? ''}';
    if (!license.startsWith('https://creativecommons.org/')) {
      return [];
    }
    final server = '${data['d1'] ?? ''}';
    final directory = '${data['dir'] ?? ''}';
    if (!server.endsWith('.archive.org') || !directory.startsWith('/')) {
      return [];
    }
    final videos = <VideoPost>[];
    for (final file
        in (data['files'] as List? ?? []).cast<Map<String, dynamic>>()) {
      final width = DirectVideoDatasource.number(file['width']);
      final height = DirectVideoDatasource.number(file['height']);
      final duration = num.tryParse('${file['length']}') ?? 0;
      final name = '${file['name']}';
      if (!name.endsWith('.mp4') ||
          width <= 0 ||
          height / width < 1.4 ||
          duration <= 0 ||
          duration > 90 ||
          DirectVideoDatasource.number(file['size']) * 8 / duration > 4000000) {
        continue;
      }
      final uri = Uri(scheme: 'https', host: server, path: '$directory/$name');
      if (!await _hasAudio(uri, DirectVideoDatasource.number(file['size']))) {
        continue;
      }
      videos.add(
        VideoPost(
          caption: '${metadata['title'] ?? id}',
          videoUrl: uri.toString(),
          source: VideoSource.internetArchive,
          externalId: '$id/$name',
          attributionUrl: 'https://archive.org/details/$id',
          licenseUrl: license,
          description:
              '${WikimediaVideoDatasource.plainText('${metadata['description'] ?? ''}')}\nAutor: ${metadata['creator'] ?? 'Ver ficha original'} · Internet Archive · $name. Se conserva el encuadre original.',
        ),
      );
    }
    return videos;
  }

  Future<bool> _hasAudio(Uri uri, int size) async {
    final key = 'audio.${uri.path}.$size';
    final cached = storage.getString('vdry.videoCache.$cacheNamespace.$key');
    if (cached != null) {
      final record = jsonDecode(cached) as Map<String, dynamic>;
      if (DateTime.now().millisecondsSinceEpoch - (record['time'] as int) <
          const Duration(hours: 24).inMilliseconds) {
        return record['audio'] == true;
      }
    }
    if (size <= 0) return false;
    // Leer como máximo 128 KiB: no descargar el video para examinarlo.
    final head = await _range(uri, 0, 65535);
    final tail = _containsAudio(head)
        ? <int>[]
        : await _range(uri, size > 65536 ? size - 65536 : 0, size - 1);
    final audio = _containsAudio(head) || _containsAudio(tail);
    await storage.setString(
      'vdry.videoCache.$cacheNamespace.$key',
      jsonEncode({
        'time': DateTime.now().millisecondsSinceEpoch,
        'audio': audio,
      }),
    );
    return audio;
  }

  static bool _containsAudio(List<int> bytes) {
    for (var i = 0; i + 16 <= bytes.length; i++) {
      if (bytes[i] == 104 &&
          bytes[i + 1] == 100 &&
          bytes[i + 2] == 108 &&
          bytes[i + 3] == 114 &&
          bytes[i + 12] == 115 &&
          bytes[i + 13] == 111 &&
          bytes[i + 14] == 117 &&
          bytes[i + 15] == 110) {
        return true;
      }
    }
    return false;
  }

  Future<List<int>> _range(Uri uri, int start, int end) async {
    final request = http.Request('GET', uri)
      ..headers['Range'] = 'bytes=$start-$end';
    final response = await client
        .send(request)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 206) {
      await response.stream.listen(null).cancel();
      throw StateError('Internet Archive: lectura parcial no disponible');
    }
    final iterator = StreamIterator(response.stream);
    final bytes = <int>[];
    try {
      while (bytes.length < 65536 &&
          await iterator.moveNext().timeout(const Duration(seconds: 15))) {
        bytes.addAll(iterator.current.take(65536 - bytes.length));
      }
    } finally {
      await iterator.cancel();
    }
    return bytes;
  }
}
