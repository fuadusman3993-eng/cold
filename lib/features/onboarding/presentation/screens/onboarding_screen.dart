import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cold/features/auth/presentation/screens/login_screen.dart';
import 'package:cold/core/localization/app_localizations.dart';
import 'package:cold/core/widgets/language_selector.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  bool _hasAgreedToTerms = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final List<String> _selectedInterests = [];
  final List<String> _interests = [
    'Quran', 'Football', 'News', 'Cold Videos', 'Technology', 
    'Lifestyle', 'Art', 'Finance', 'Travel', 'Food', 'Movies', 'Gaming', 'Science'
  ];

  static const Color _electricBlue = Color(0xFF0088FF);
  static const Color _charcoal = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: _hasAgreedToTerms ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
        children: [
          _buildFirstOnboardingView(context),
          _buildSalatView(context),
          _buildPermissionsView(context),
          _buildInterestsView(context),
        ],
      ),
    );
  }

  // --- PAGE 1: Initial Gated Onboarding ---
  Widget _buildFirstOnboardingView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    if (_hasAgreedToTerms) _pulseController.stop();
    
    return Stack(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 12.0, end: _hasAgreedToTerms ? 0.0 : 12.0),
          duration: _hasAgreedToTerms ? Duration.zero : const Duration(milliseconds: 800),
          builder: (context, blurValue, child) {
            return ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
              child: AnimatedOpacity(
                duration: _hasAgreedToTerms ? Duration.zero : const Duration(milliseconds: 800),
                opacity: _hasAgreedToTerms ? 1.0 : 0.3,
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/world_map.png',
                      width: size.width,
                      height: isDesktop ? size.height * 0.45 : size.height * 0.35,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white.withOpacity(0.05), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.04),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? size.width * 0.2 : 32.0),
                      child: Column(
                        children: [
                          _buildFeatureItem(
                            Icons.psychology_outlined,
                            l10n.translate('islamic_ai_title'),
                            l10n.translate('islamic_ai_subtitle'),
                            size,
                          ),
                          SizedBox(height: size.height * 0.04),
                          _buildFeatureItem(
                            Icons.security_outlined,
                            l10n.translate('advanced_security_title'),
                            l10n.translate('advanced_security_subtitle'),
                            size,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 16,
          child: const LanguageSelector(),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(isDesktop ? size.width * 0.2 : 32.0, 0, isDesktop ? size.width * 0.2 : 32.0, 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: _hasAgreedToTerms ? [] : [
                              BoxShadow(color: _electricBlue.withOpacity(0.4), blurRadius: _pulseAnimation.value, spreadRadius: _pulseAnimation.value / 2)
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: Checkbox(
                          value: _hasAgreedToTerms,
                          onChanged: (value) => setState(() => _hasAgreedToTerms = value ?? false),
                          activeColor: _electricBlue,
                          checkColor: Colors.white,
                          side: const BorderSide(color: Colors.white38, width: 1.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.translate('terms_agreement'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _hasAgreedToTerms ? Colors.white : Colors.white60, fontSize: isDesktop ? 12 : 9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildActionButton(context, l10n.translate('continue'), _hasAgreedToTerms, _nextPage, isDesktop),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- PAGE 2: Salat View ---
  Widget _buildSalatView(BuildContext context) {
    return AnimatedInfoSlide(
      title: "Salat to guide your day",
      accentColor: _electricBlue,
      onAutoScroll: _nextPage,
    );
  }

  // --- PAGE 3: Permissions View ---
  Widget _buildPermissionsView(BuildContext context) {
    return AnimatedInfoSlide(
      icon: Icons.notifications_active_outlined,
      title: "Allow permissions",
      subtitle: "Stay notified about prayers and analysis updates",
      accentColor: _electricBlue,
      onAutoScroll: _nextPage,
    );
  }

  // --- PAGE 4: Interests View ---
  Widget _buildInterestsView(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Text(
              "Choose what you like",
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Select your favorite topics to personalize your feed",
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _interests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedInterests.remove(interest);
                          } else {
                            _selectedInterests.add(interest);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? _electricBlue : const Color(0xFF222222),
                            width: 1.5,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: _electricBlue.withOpacity(0.15), blurRadius: 10, spreadRadius: 1)
                          ] : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child));
                              },
                              child: Icon(
                                isSelected ? Icons.check : Icons.add,
                                key: ValueKey<bool>(isSelected),
                                color: isSelected ? _electricBlue : Colors.white54,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              interest,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _handleSkip(context),
                    child: const Text("Skip", style: TextStyle(color: Colors.white38)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: _buildActionButton(
                    context, 
                    _selectedInterests.length < 3 ? "Select 3+ (${_selectedInterests.length})" : "Next (${_selectedInterests.length})", 
                    _selectedInterests.length >= 3, 
                    _finishOnboarding, 
                    isDesktop
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _handleSkip(BuildContext context) {
    if (_selectedInterests.isEmpty) {
      _showSkipOverlay(context);
    } else {
      _finishOnboarding();
    }
  }

  void _showSkipOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white10, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              const Icon(Icons.auto_awesome_outlined, color: _electricBlue, size: 48),
              const SizedBox(height: 24),
              Text(
                "Personalize your feed",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Selecting topics helps us curate a personalized experience for you. Are you sure you want to skip?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 32),
              _buildActionButton(
                context, 
                "Let me choose", 
                true, 
                () => Navigator.pop(context), 
                false
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _finishOnboarding();
                },
                child: const Text(
                  "Proceed anyway", 
                  style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, String text, bool enabled, VoidCallback onPressed, bool isDesktop) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled ? [BoxShadow(color: _electricBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 4))] : [],
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? _electricBlue : const Color(0xFF111111),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF111111),
          disabledForegroundColor: Colors.white24,
          minimumSize: Size(double.infinity, isDesktop ? 64 : 56),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w900, fontSize: isDesktop ? 18 : 15)),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, Size screenSize) {
    final isDesktop = screenSize.width > 900;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isDesktop ? 10 : 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(isDesktop ? 12 : 8)),
          child: Icon(icon, color: Colors.white, size: isDesktop ? 24 : 18),
        ),
        SizedBox(width: isDesktop ? 20 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: isDesktop ? 16 : 14, letterSpacing: -0.1)),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60, fontSize: isDesktop ? 12 : 10, height: 1.2)),
            ],
          ),
        ),
      ],
    );
  }
}

class AnimatedInfoSlide extends StatefulWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final VoidCallback onAutoScroll;

  const AnimatedInfoSlide({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.accentColor,
    required this.onAutoScroll,
  });

  @override
  State<AnimatedInfoSlide> createState() => _AnimatedInfoSlideState();
}

class _AnimatedInfoSlideState extends State<AnimatedInfoSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: widget.accentColor, size: 72),
                  ),
                  const SizedBox(height: 40),
                ],
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
