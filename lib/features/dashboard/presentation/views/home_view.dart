import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Custom Top Bar
              SliverAppBar(
                backgroundColor: Colors.black,
                elevation: 0,
                floating: true,
                pinned: false,
                leading: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {},
                ),
                title: Text(
                  'COLD',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    fontSize: 24,
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
              
              // Story Section (Horizontal Scroll)
              SliverToBoxAdapter(
                child: _buildStoriesSection(),
              ),

              // Feed Navigation (TabBar)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    indicatorColor: Colors.white,
                    indicatorWeight: 2,
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
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildFeedDummy('For You Feed'),
              _buildFeedDummy('Following Feed'),
            ],
          ),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black, // Opaque background prevents overlap visual issues
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
