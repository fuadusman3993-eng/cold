import 'package:video_player/video_player.dart';
import 'video_player_helper_stub.dart'
    if (dart.library.html) 'video_player_helper_web.dart'
    if (dart.library.io) 'video_player_helper_mobile.dart';

VideoPlayerController createVideoPlayerController(String url) {
  return createController(url);
}
