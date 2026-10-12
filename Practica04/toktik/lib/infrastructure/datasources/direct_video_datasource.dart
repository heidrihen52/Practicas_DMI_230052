import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/datasources/video_posts_datasource.dart';
import '../../domain/entities/video_post.dart';

/// Caché de metadatos: nunca almacena credenciales ni descarga los MP4.
abstract class DirectVideoDatasource implements VideoPostDatasource {
  final http.Client client;
  final SharedPreferences storage;
  final String cacheNamespace;
  DirectVideoDatasource(this.client, this.storage, this.cacheNamespace);
  Future<Map<String, dynamic>> getJson(
    Uri uri,
    String cacheId, {
    Map<String, String>? headers,
  }) async {
    final key = 'vdry.videoCache.$cacheNamespace.$cacheId';
    final cached = storage.getString(key);
    if (cached != null) {
      try {
        final record = jsonDecode(cached) as Map<String, dynamic>;
        final age =
            DateTime.now().millisecondsSinceEpoch - (record['time'] as int);
        if (age >= 0 && age < const Duration(hours: 24).inMilliseconds) {
          return record['data'] as Map<String, dynamic>;
        }
      } catch (_) {
        /* Una caché inválida se reemplaza con la respuesta real. */
      }
    }
    final response = await client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError('$cacheNamespace: HTTP ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    await storage.setString(
      key,
      jsonEncode({'time': DateTime.now().millisecondsSinceEpoch, 'data': data}),
    );
    return data;
  }

  @override
  Future<List<VideoPost>> getFavoriteVideosByUser(String userID) async => [];

  static int number(dynamic value) => int.tryParse('$value') ?? 0;
}
