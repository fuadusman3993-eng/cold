import 'package:flutter/material.dart';

class VideoModel {
  final String id;
  final String title;
  final String username;
  final String url;
  final List<Color> colors;

  VideoModel({
    required this.id,
    required this.title,
    required this.username,
    required this.url,
    required this.colors,
  });
}

class FeedProvider extends ChangeNotifier {
  final List<VideoModel> _followingVideos = [];
  final List<VideoModel> _forYouVideos = [];

  List<VideoModel> get followingVideos => _followingVideos;
  List<VideoModel> get forYouVideos => _forYouVideos;

  FeedProvider() {
    _populateInitialFeeds();
  }

  void _populateInitialFeeds() {
    final colors = [
      [const Color(0xFF1A2980), const Color(0xFF26D0CE)], // Blue/Cyan
      [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)], // Deep Purple
      [const Color(0xFF0F2027), const Color(0xFF203A43)], // Dark Slate
      [const Color(0xFF373B44), const Color(0xFF4286f4)], // Grey/Blue
    ];

    for (int i = 0; i < 5; i++) {
      final colorPair = colors[i % colors.length];
      _followingVideos.add(
        VideoModel(
          id: 'following_$i',
          title: 'Premium post from following list',
          username: 'creator_$i',
          url: '',
          colors: colorPair,
        ),
      );
      _forYouVideos.add(
        VideoModel(
          id: 'foryou_$i',
          title: 'Premium content tailored for you',
          username: 'explorer_$i',
          url: '',
          colors: colorPair,
        ),
      );
    }
  }

  /// Inserts a new video at index 0 of the 'For You' list
  void addVideoToForYou(VideoModel video) {
    _forYouVideos.insert(0, video);
    notifyListeners();
  }

  /// Inserts a new video at index 0 of the 'Following' list
  void addVideoToFollowing(VideoModel video) {
    _followingVideos.insert(0, video);
    notifyListeners();
  }
}
