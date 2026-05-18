import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import 'package:video_player/video_player.dart';

VideoPlayerController createVideoPlayerController(String url) {
  if (kIsWeb) {
    return VideoPlayerController.networkUrl(Uri.parse(url));
  } else {
    final isLocal = !(url.startsWith('http://') || url.startsWith('https://') || url.startsWith('blob:') || url.startsWith('assets/'));
    if (isLocal) {
      return VideoPlayerController.file(File(url));
    } else {
      return VideoPlayerController.networkUrl(Uri.parse(url));
    }
  }
}
