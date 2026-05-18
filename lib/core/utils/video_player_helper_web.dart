import 'package:video_player/video_player.dart';

VideoPlayerController createController(String url) {
  // Web always uses networkUrl
  return VideoPlayerController.networkUrl(Uri.parse(url));
}
