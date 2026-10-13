import 'package:flutter/services.dart';

import '../../domain/services/local_video_playback_service.dart';

class BundledVideoPlaybackService implements LocalVideoPlaybackService {
  final Future<Set<String>> Function()? assetPaths;
  Future<Set<String>>? _manifest;
  BundledVideoPlaybackService({this.assetPaths});
  Future<Set<String>> _assets() async =>
      (await AssetManifest.loadFromAssetBundle(rootBundle))
          .listAssets()
          .toSet();
  @override
  Future<String> resolve(String originalAsset) async {
    final assets = await (_manifest ??= (assetPaths ?? _assets)());
    final variant = 'assets/videos/playback/${originalAsset.split('/').last}';
    return assets.contains(variant) ? variant : originalAsset;
  }
}
