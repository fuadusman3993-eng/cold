import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cold/features/post/presentation/screens/create_post_screen.dart';
import 'package:cold/core/utils/navigation_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cold/core/providers/feed_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cold/core/utils/video_player_helper.dart';

Future<void> _handlePlusButtonTap(BuildContext context) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool hasGrantedPermissions = prefs.getBool('permissions_granted') ?? false;

  if (hasGrantedPermissions) {
    if (context.mounted) {
      Navigator.pushNamed(context, '/clean_camera_screen');
    }
    return;
  }

  final cameraStatus = await Permission.camera.status;
  final micStatus = await Permission.microphone.status;

  if (cameraStatus.isGranted && micStatus.isGranted) {
    await prefs.setBool('permissions_granted', true);
    if (context.mounted) {
      Navigator.pushNamed(context, '/clean_camera_screen');
    }
    return;
  }

  final Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.microphone,
  ].request();

  final isCameraGranted = statuses[Permission.camera]?.isGranted == true;
  final isMicGranted = statuses[Permission.microphone]?.isGranted == true;

  if (isCameraGranted && isMicGranted) {
    await prefs.setBool('permissions_granted', true);
    if (context.mounted) {
      Navigator.pushNamed(context, '/clean_camera_screen');
    }
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF000000),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80.0, left: 16.0, right: 16.0),
          content: Text(
            'Camera and Microphone permissions are required to create posts.',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      animationDuration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabTap(int index) {
    if (_tabController.index == index) return;
    _tabController.animateTo(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      extendBodyBehindAppBar: true, 
      body: Stack(
        children: [
          // BASE LAYER: Full-screen scrollable feeds
          Positioned.fill(
            child: TabBarView(
              controller: _tabController,
              physics: const ClampingScrollPhysics(),
              children: const [
                ImmersiveFeed(title: 'Following'),
                ImmersiveFeed(title: 'For You'),
              ],
            ),
          ),
          
          // TOP OVERLAY LAYER: UI elements floating over the media
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left side: Cold Logo
                          Text(
                            'Cold',
                            style: GoogleFonts.pacifico(
                              color: Colors.white,
                              fontSize: 24,
                              letterSpacing: 1.0,
                            ),
                          ),
                          // TikTok-Style Centered Tabs
                          SizedBox(
                            width: 220,
                            child: TabBar(
                              controller: _tabController,
                              onTap: _handleTabTap,
                              dividerColor: Colors.transparent, // Remove default flutter divider line
                              indicator: UnderlineTabIndicator(
                                borderSide: const BorderSide(color: Colors.white, width: 3.0),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
                              indicatorSize: TabBarIndicatorSize.label,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white60,
                              labelStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                shadows: [const Shadow(color: Colors.black45, blurRadius: 4)],
                              ),
                              unselectedLabelStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                shadows: [const Shadow(color: Colors.black45, blurRadius: 4)],
                              ),
                              tabs: const [
                                Tab(text: "Following"),
                                Tab(text: "For You"),
                              ],
                            ),
                          ),
                          // Right side: Actions (+ and Search)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedScaleButton(
                                onTap: () => _handlePlusButtonTap(context),
                                child: const Icon(LucideIcons.plus, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              AnimatedScaleButton(
                                onTap: () {},
                                child: const Icon(LucideIcons.search, color: Colors.white, size: 28),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Story Section (Only visible on 'Following' tab)
                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, child) {
                        return AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.fastOutSlowIn,
                          child: _tabController.index == 0
                              ? _buildStoriesSection()
                              : const SizedBox.shrink(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesSection() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 10,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final isAddStory = index == 0;
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAddStory ? Colors.transparent : Colors.white,
                      width: 2,
                    ),
                    color: Colors.white10,
                  ),
                  child: isAddStory
                      ? const Icon(LucideIcons.plus, color: Colors.white)
                      : const Icon(LucideIcons.user, color: Colors.white54),
                ),
                const SizedBox(height: 4),
                Text(
                  isAddStory ? 'Your Story' : 'User $index',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    shadows: [
                      Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2)
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
class ImmersiveFeed extends StatefulWidget {
  final String title;
  const ImmersiveFeed({super.key, required this.title});

  @override
  State<ImmersiveFeed> createState() => _ImmersiveFeedState();
}

class _ImmersiveFeedState extends State<ImmersiveFeed> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final feedProvider = Provider.of<FeedProvider>(context);
    final videos = widget.title == 'Following' 
        ? feedProvider.followingVideos 
        : feedProvider.forYouVideos;

    if (videos.isEmpty) {
      return const Center(
        child: Text(
          'No posts available.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return FeedPostItem(video: video);
      },
    );
  }
}

class FeedPostItem extends StatefulWidget {
  final VideoModel video;
  const FeedPostItem({super.key, required this.video});

  @override
  State<FeedPostItem> createState() => _FeedPostItemState();
}

class _FeedPostItemState extends State<FeedPostItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final url = widget.video.url;
    if (url.isEmpty) return; // Keep rendering gradient placeholder

    _controller = createVideoPlayerController(url);

    try {
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading feed video: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full-screen background gradient fallback / placeholder
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.video.colors,
              ),
            ),
          ),
        ),

        // 2. Video Player Layer with exact Initialization Guard
        if (_controller != null)
          Positioned.fill(
            child: _controller!.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0088FF),
                    ),
                  ),
          ),

        // Bottom-Left Content Overlay (User Name & Title)
        Positioned(
          bottom: 80, // Tightly positioned just above the bottom navigation bar
          left: 16,
          right: 80, // Leaves room for the right interaction panel
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@${widget.video.username}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    const Shadow(color: Colors.black54, blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.video.title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  shadows: [
                    const Shadow(color: Colors.black54, blurRadius: 4),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Floating Interaction Panel (TikTok Style)
        _InteractionPanel(video: widget.video),
      ],
    );
  }
}

// Custom widget for premium micro-animations on icons
class AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedScaleButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

class _InteractionPanel extends StatelessWidget {
  final VideoModel video;
  const _InteractionPanel({required this.video});

  void _showShareMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A), // Extremely dark minimalist black
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Share & Actions',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Horizontal Action List
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildShareOption(
                        context: context,
                        icon: LucideIcons.repeat,
                        label: 'Repost',
                        color: const Color(0xFF0088FF), // Premium blue accent
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF161616),
                              content: Text(
                                'Reposted successfully!',
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      _buildShareOption(
                        context: context,
                        icon: LucideIcons.link,
                        label: 'Copy Link',
                        color: Colors.white.withOpacity(0.08),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF161616),
                              content: Text(
                                'Link copied to clipboard!',
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      _buildShareOption(
                        context: context,
                        icon: LucideIcons.send,
                        label: 'Send',
                        color: Colors.white.withOpacity(0.08),
                        onTap: () => Navigator.pop(context),
                      ),
                      _buildShareOption(
                        context: context,
                        icon: LucideIcons.bookmark,
                        label: 'Collection',
                        color: Colors.white.withOpacity(0.08),
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: AnimatedScaleButton(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              child: Center(
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);

    return Positioned(
      bottom: 90, // Positioned optimally above the bottom nav bar
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Micro-resized profile avatar shifted to the top
          _buildProfileAvatar(context),
          const SizedBox(height: 24), // Elegant separation between avatar and first button
          
          // Interactions (Like, Comment, Bookmark, Share)
          _buildInteractionButton(
            video.isLiked ? Icons.favorite : LucideIcons.heart, 
            video.likesCount.toString(), 
            color: video.isLiked ? const Color(0xFFFF2D55) : Colors.white,
            onTap: () {
              feedProvider.toggleLike(video.id);
            },
          ),
          const SizedBox(height: 20),
          _buildInteractionButton(
            LucideIcons.messageCircle, 
            video.commentsCount.toString(), 
            onTap: () {},
          ),
          const SizedBox(height: 20),
          _buildInteractionButton(
            LucideIcons.bookmark, 
            '336', 
            onTap: () {},
          ),
          const SizedBox(height: 20),
          _buildInteractionButton(
            LucideIcons.send, 
            'Share', 
            onTap: () => _showShareMenu(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 52,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              color: Colors.white10,
            ),
            child: const Icon(LucideIcons.user, color: Colors.white70, size: 20),
          ),
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: () => _handlePlusButtonTap(context),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0088FF), // Premium blue accent
                ),
                child: const Icon(LucideIcons.plus, color: Colors.white, size: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(IconData icon, String label, {required VoidCallback onTap, Color color = Colors.white, bool isMirrored = false}) {
    Widget iconWidget = Icon(
      icon,
      color: color,
      size: 28, // Sized down to 28 for ultra-minimalist, thin-stroke feel
      shadows: [
        Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 6, offset: const Offset(0, 1)),
      ],
    );

    if (isMirrored) {
      iconWidget = Transform.scale(
        scaleX: -1,
        child: iconWidget,
      );
    }

    return AnimatedScaleButton(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11, // Delicate minimalist size
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4, offset: const Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
