import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toktik/infrastructure/datasources/peertube_video_datasource.dart';
import 'package:toktik/infrastructure/datasources/internet_archive_video_datasource.dart';
import 'package:toktik/infrastructure/datasources/wikimedia_video_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Verificación de las tres APIs reales sin credenciales',
    () async {
      HttpOverrides.global = null;
      SharedPreferences.setMockInitialValues({});
      final storage = await SharedPreferences.getInstance();
      final client = http.Client();
      addTearDown(client.close);
      final sources = [
        PeerTubeVideoDatasource(client, storage),
        InternetArchiveVideoDatasource(client, storage),
        WikimediaVideoDatasource(client, storage),
      ];
      await Future.wait(
        sources.map((source) async {
          final videos = await source.getTrendingVideosByPage(1);
          debugPrint(
            '${source.runtimeType}: ${videos.length} videos; ${videos.firstOrNull?.videoUrl}',
          );
          expect(videos, isNotEmpty);
        }),
      );
    },
    skip: !const bool.fromEnvironment('VERIFY_PUBLIC_APIS'),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
