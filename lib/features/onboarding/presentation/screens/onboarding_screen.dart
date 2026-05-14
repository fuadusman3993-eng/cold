import 'package:flutter/material.dart';
import 'package:cold/features/auth/presentation/screens/login_screen.dart';
import 'package:cold/core/localization/app_localizations.dart';
import 'package:cold/core/widgets/language_selector.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _currentPageValue = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPageValue = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final l10n = AppLocalizations.of(context)!;
    
    final List<OnboardingData> pages = [
      OnboardingData(
        title: 'Universal Connectivity',
        subtitle: 'A borderless digital ecosystem built for the global community.',
        imagePath: 'assets/images/world_map.png',
      ),
      OnboardingData(
        title: 'Visionary Intelligence',
        subtitle: 'Advanced algorithms meeting traditional wisdom for modern insights.',
        imagePath: 'assets/images/islamic_ai.png',
      ),
      OnboardingData(
        title: 'Inviolable Security',
        subtitle: 'Bank-grade encryption anchored in divine protection.',
        imagePath: 'assets/images/security.png',
        arabicOverlay: 'الله خير حافظاً',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [LanguageSelector()],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            itemBuilder: (context, index) {
              double relativePosition = index - _currentPageValue;
              double scale = (1.0 - (relativePosition.abs() * 0.3)).clamp(0.7, 1.0);
              double opacity = (1.0 - relativePosition.abs()).clamp(0.0, 1.0);

              return OnboardingPage(
                data: pages[index],
                scale: scale,
                opacity: opacity,
              );
            },
          ),
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 4,
                      width: _currentPageValue.round() == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPageValue.round() == index
                            ? Colors.white
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPageValue < pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              const LoginScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 800),
                        ),
                      );
                    }
                  },
                  child: Text(_currentPageValue.round() == pages.length - 1
                      ? 'Commence Journey'
                      : 'Continue'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String imagePath;
  final String? arabicOverlay;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    this.arabicOverlay,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final double scale;
  final double opacity;

  const OnboardingPage({
    super.key,
    required this.data,
    required this.scale,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    data.imagePath,
                    height: 350,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 350,
                      color: Colors.black,
                      child: const Icon(Icons.image_not_supported,
                          size: 50, color: Colors.white24),
                    ),
                  ),
                  if (data.arabicOverlay != null)
                    Positioned(
                      top: 155,
                      child: Text(
                        data.arabicOverlay!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Amiri',
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Opacity(
            opacity: opacity,
            child: Column(
              children: [
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        letterSpacing: -1.0,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
