import 'dart:io';
import 'package:video_player/video_player.dart';

VideoPlayerController createController(String url) {
  final isLocal = !(url.startsWith('http://') || url.startsWith('https://') || url.startsWith('blob:') || url.startsWith('assets/'));
  if (isLocal) {
    return VideoPlayerController.file(File(url));
  } else {
    return VideoPlayerController.networkUrl(Uri.parse(url));
  }
}
