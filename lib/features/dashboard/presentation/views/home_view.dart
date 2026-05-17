import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cold/features/post/presentation/screens/create_post_screen.dart';

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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CreatePostScreen(),
                                      fullscreenDialog: true,
                                    ),
                                  );
                                },
                                child: const Icon(Icons.add, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              AnimatedScaleButton(
                                onTap: () {},
                                child: const Icon(Icons.search, color: Colors.white, size: 28),
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
                      ? const Icon(Icons.add, color: Colors.white)
                      : const Icon(Icons.person, color: Colors.white54),
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
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: 10,
      itemBuilder: (context, index) {
        // Generating vibrant gradients to simulate beautiful media
        final colors = [
          [const Color(0xFF1A2980), const Color(0xFF26D0CE)], // Blue/Cyan
          [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)], // Deep Purple
          [const Color(0xFF0F2027), const Color(0xFF203A43)], // Dark Slate
          [const Color(0xFF373B44), const Color(0xFF4286f4)], // Grey/Blue
        ];
        final colorPair = colors[index % colors.length];

        return Stack(
          children: [
            // Full-screen background media forced to edges with zero margins
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colorPair,
                  ),
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
                    '@username_$index',
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
                    '${widget.title} - This is a sample video post description designed to match the premium TikTok aesthetic.',
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
            const _InteractionPanel(),
          ],
        );
      },
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
  const _InteractionPanel();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProfileAvatar(),
          const SizedBox(height: 18),
          _buildInteractionButton(Icons.favorite, '8,497'),
          const SizedBox(height: 16),
          _buildInteractionButton(Icons.chat_bubble_outline, '77'), // Premium outline bubble
          const SizedBox(height: 16),
          _buildInteractionButton(Icons.bookmark, '336'),
          const SizedBox(height: 16),
          _buildInteractionButton(Icons.reply, 'Share', isMirrored: true),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return SizedBox(
      width: 56,
      height: 68,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.white10,
            ),
            child: const Icon(Icons.person, color: Colors.white54, size: 30),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0088FF), // Premium blue accent
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(IconData icon, String label, {bool isMirrored = false}) {
    Widget iconWidget = Icon(
      icon,
      color: Colors.white,
      size: 32, // Scaled down for a sleeker profile
      shadows: [
        Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 8, offset: const Offset(0, 1)),
      ],
    );

    if (isMirrored) {
      iconWidget = Transform.scale(
        scaleX: -1, // Flips the icon horizontally to match social media 'Share' direction
        child: iconWidget,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12, // Scaled down label size
            shadows: [
              Shadow(color: Colors.black.withOpacity(0.6), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
        ),
      ],
    );
  }
}
