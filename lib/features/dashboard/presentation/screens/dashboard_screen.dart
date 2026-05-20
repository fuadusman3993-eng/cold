import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cold/features/dashboard/presentation/views/home_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    final scaffold = Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          const HomeView(),
          _buildPlaceholderView("Create", LucideIcons.plus),
          _buildPlaceholderView("AI Analysis", LucideIcons.brain),
          _buildPlaceholderView("Messages", LucideIcons.send),
          _buildPlaceholderView("Profile", LucideIcons.user),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              backgroundColor: Colors.black,
              elevation: 0,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white60,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
              currentIndex: _currentIndex,
              onTap: _onItemTapped,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(LucideIcons.triangle),
                  activeIcon: Icon(LucideIcons.triangle, shadows: [Shadow(color: Colors.white, blurRadius: 8)]),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Text('C', style: GoogleFonts.pacifico(color: Colors.white60, fontSize: 20)),
                  activeIcon: Text('C', style: GoogleFonts.pacifico(color: Colors.white, fontSize: 22, shadows: [const Shadow(color: Colors.white, blurRadius: 8)])),
                  label: '',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(LucideIcons.brain),
                  activeIcon: Icon(LucideIcons.brain, shadows: [Shadow(color: Colors.white, blurRadius: 8)]),
                  label: 'AI',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(LucideIcons.send),
                  activeIcon: Icon(LucideIcons.send, shadows: [Shadow(color: Colors.white, blurRadius: 8)]),
                  label: 'Message',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(LucideIcons.user),
                  activeIcon: Icon(LucideIcons.user, shadows: [Shadow(color: Colors.white, blurRadius: 8)]),
                  label: 'Profile',
                ),
              ],
            ),
    );

    return Container(
      color: Colors.black,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          child: scaffold,
        ),
      ),
    );
  }

  Widget _buildPlaceholderView(String title, IconData icon) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.white24),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
