import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedScaleButton(
                    onTap: () {},
                    child: const Icon(Icons.add, color: Colors.white, size: 32),
                  ),
                  Text(
                    'COLD',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      fontSize: 24,
                    ),
                  ),
                  AnimatedScaleButton(
                    onTap: () {},
                    child: const Icon(Icons.search, color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
            
            // Fixed Story Section (Horizontal Scroll)
            _buildStoriesSection(),

            // Fixed Feed Navigation (TabBar)
            TabBar(
              controller: _tabController,
              onTap: _handleTabTap,
              indicator: UnderlineTabIndicator(
                borderSide: const BorderSide(color: Colors.white, width: 4.0),
                borderRadius: BorderRadius.circular(4),
              ),
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              tabs: const [
                Tab(text: "For You"),
                Tab(text: "Following"),
              ],
            ),
            
            // Scrollable Feeds
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const ClampingScrollPhysics(), // Provide standard paging physics
                children: [
                  _buildFeedDummy('For You Feed'),
                  _buildFeedDummy('Following Feed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesSection() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 10,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final isAddStory = index == 0;
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
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
                const SizedBox(height: 6),
                Text(
                  isAddStory ? 'Your Story' : 'User $index',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedDummy(String title) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 80),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          height: 300,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '$title - Post $index',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
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
