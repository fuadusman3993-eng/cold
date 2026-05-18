import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'video_player_file_stub.dart'
    if (dart.library.io) 'video_player_file_mobile.dart' as file_controller;

VideoPlayerController createVideoPlayerController(String url) {
  if (kIsWeb) {
    return VideoPlayerController.networkUrl(Uri.parse(url));
  } else {
    final isLocal = !(url.startsWith('http://') || url.startsWith('https://') || url.startsWith('blob:') || url.startsWith('assets/'));
    if (isLocal) {
      return file_controller.getFileVideoPlayerController(url);
    } else {
      return VideoPlayerController.networkUrl(Uri.parse(url));
    }
  }
}
