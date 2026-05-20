import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VideoModel {
  final String id;
  final String title;
  final String username;
  final String url;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final List<Color> colors;

  VideoModel({
    required this.id,
    required this.title,
    required this.username,
    required this.url,
    required this.likesCount,
    required this.commentsCount,
    this.isLiked = false,
    required this.colors,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json, {bool isLiked = false, List<Color>? fallbackColors}) {
    String user = 'explorer';
    if (json['profiles'] != null && json['profiles']['username'] != null) {
      user = json['profiles']['username'];
    }

    final colorsList = [
      [const Color(0xFF1A2980), const Color(0xFF26D0CE)], // Blue/Cyan
      [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)], // Deep Purple
      [const Color(0xFF0F2027), const Color(0xFF203A43)], // Dark Slate
      [const Color(0xFF373B44), const Color(0xFF4286f4)], // Grey/Blue
    ];
    final hash = json['id'].toString().hashCode;
    final selectedColors = colorsList[hash % colorsList.length];

    return VideoModel(
      id: json['id'].toString(),
      title: json['description'] ?? 'Premium content on Cold',
      username: user,
      url: json['video_url'] ?? '',
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: isLiked,
      colors: fallbackColors ?? selectedColors,
    );
  }

  VideoModel copyWith({
    String? id,
    String? title,
    String? username,
    String? url,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    List<Color>? colors,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      url: url ?? this.url,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      colors: colors ?? this.colors,
    );
  }
}

class FeedProvider extends ChangeNotifier {
  final List<VideoModel> _followingVideos = [];
  final List<VideoModel> _forYouVideos = [];
  bool _isLoading = false;

  List<VideoModel> get followingVideos => _followingVideos;
  List<VideoModel> get forYouVideos => _forYouVideos;
  bool get isLoading => _isLoading;

  FeedProvider() {
    fetchFeeds();
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
          likesCount: 120 + i * 5,
          commentsCount: 12 + i,
          isLiked: false,
          colors: colorPair,
        ),
      );
      _forYouVideos.add(
        VideoModel(
          id: 'foryou_$i',
          title: 'Premium content tailored for you',
          username: 'explorer_$i',
          url: '',
          likesCount: 8497 + i * 15,
          commentsCount: 77 + i * 2,
          isLiked: false,
          colors: colorPair,
        ),
      );
    }
  }

  Future<void> fetchFeeds() async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id ?? '00000000-0000-0000-0000-000000000000';

      // 1. Fetch videos with profiles join
      final List<dynamic> videosData = await client
          .from('videos')
          .select('*, profiles(username)')
          .order('created_at', ascending: false);

      // 2. Fetch current user likes
      List<String> likedVideoIds = [];
      try {
        final List<dynamic> likesData = await client
            .from('video_likes')
            .select('video_id')
            .eq('user_id', userId);
        likedVideoIds = likesData.map((like) => like['video_id'].toString()).toList();
      } catch (e) {
        debugPrint('Could not fetch video likes (checking if table exists): $e');
      }

      // 3. Clear existing list and parse new data
      _followingVideos.clear();
      _forYouVideos.clear();

      for (var json in videosData) {
        final String videoId = json['id'].toString();
        final bool isLiked = likedVideoIds.contains(videoId);
        
        final video = VideoModel.fromJson(json, isLiked: isLiked);
        
        // Split or duplicate to both feeds
        _forYouVideos.add(video);
        _followingVideos.add(video);
      }

      // 4. Fallback in case table is empty to keep app functional with mock data
      if (_forYouVideos.isEmpty) {
        _populateInitialFeeds();
      }
    } catch (e) {
      debugPrint('Error fetching feeds from Supabase: $e');
      // Fallback to mock data so app doesn't break
      if (_forYouVideos.isEmpty) {
        _populateInitialFeeds();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String videoId) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id ?? '00000000-0000-0000-0000-000000000000';

    // 1. Find the video in both lists
    int forYouIndex = _forYouVideos.indexWhere((v) => v.id == videoId);
    int followingIndex = _followingVideos.indexWhere((v) => v.id == videoId);

    if (forYouIndex == -1 && followingIndex == -1) return;

    // Get current state
    final VideoModel originalVideo = forYouIndex != -1 
        ? _forYouVideos[forYouIndex] 
        : _followingVideos[followingIndex];

    final bool wasLiked = originalVideo.isLiked;
    final int newLikesCount = wasLiked 
        ? (originalVideo.likesCount - 1).clamp(0, 999999) 
        : originalVideo.likesCount + 1;

    // 2. Optimistic UI update
    final updatedVideo = originalVideo.copyWith(
      isLiked: !wasLiked,
      likesCount: newLikesCount,
    );

    if (forYouIndex != -1) {
      _forYouVideos[forYouIndex] = updatedVideo;
    }
    if (followingIndex != -1) {
      _followingVideos[followingIndex] = updatedVideo;
    }
    notifyListeners();

    try {
      // 3. Call backend RPC
      final response = await client.rpc(
        'toggle_video_like',
        params: {'video_id_param': videoId},
      );
      
      final bool serverLiked = response as bool;

      // Double-check if the server returned state matches the optimistic state
      if (serverLiked != !wasLiked) {
        // If not matching, update with server-returned state
        final serverUpdatedVideo = originalVideo.copyWith(
          isLiked: serverLiked,
          likesCount: serverLiked ? (originalVideo.likesCount + 1) : (originalVideo.likesCount - 1).clamp(0, 999999),
        );
        if (forYouIndex != -1) {
          _forYouVideos[forYouIndex] = serverUpdatedVideo;
        }
        if (followingIndex != -1) {
          _followingVideos[followingIndex] = serverUpdatedVideo;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling like on Supabase: $e');
      // Rollback to original state on failure
      if (forYouIndex != -1) {
        _forYouVideos[forYouIndex] = originalVideo;
      }
      if (followingIndex != -1) {
        _followingVideos[followingIndex] = originalVideo;
      }
      notifyListeners();
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

  /// Removes a video by ID from both feeds
  void removeVideo(String videoId) {
    _followingVideos.removeWhere((v) => v.id == videoId);
    _forYouVideos.removeWhere((v) => v.id == videoId);
    notifyListeners();
  }
}
