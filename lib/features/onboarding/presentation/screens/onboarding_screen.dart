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

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  bool _hasAgreedToTerms = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Color _electricBlue = Color(0xFF2196F3);
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_hasAgreedToTerms) {
      _pulseController.stop();
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [LanguageSelector()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Blurred Content Section
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 12.0, end: _hasAgreedToTerms ? 0.0 : 12.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, blurValue, child) {
                    return ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 800),
                        opacity: _hasAgreedToTerms ? 1.0 : 0.3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            Image.asset(
                              'assets/images/world_map.png',
                              height: 300,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [Colors.white.withOpacity(0.05), Colors.transparent],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 50),
                            _buildFeatureItem(
                              Icons.psychology_outlined,
                              l10n.translate('islamic_ai_title'),
                              l10n.translate('islamic_ai_subtitle'),
                            ),
                            const SizedBox(height: 28),
                            _buildFeatureItem(
                              Icons.security_outlined,
                              l10n.translate('advanced_security_title'),
                              l10n.translate('advanced_security_subtitle'),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // 2. Interactive Section (Unblurred)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    // Pulsing Checkbox Row
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: _hasAgreedToTerms ? [] : [
                                  BoxShadow(
                                    color: _electricBlue.withOpacity(0.4),
                                    blurRadius: _pulseAnimation.value,
                                    spreadRadius: _pulseAnimation.value / 2,
                                  )
                                ],
                              ),
                              child: child,
                            );
                          },
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: Checkbox(
                              value: _hasAgreedToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _hasAgreedToTerms = value ?? false;
                                });
                              },
                              activeColor: _electricBlue,
                              checkColor: Colors.white,
                              side: const BorderSide(color: Colors.white38, width: 1.0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.translate('terms_agreement'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _hasAgreedToTerms ? Colors.white : Colors.white60,
                              fontWeight: FontWeight.w400,
                              fontSize: 10, // Further reduced from 11
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Action Button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _hasAgreedToTerms
                            ? [
                                BoxShadow(
                                  color: _electricBlue.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: ElevatedButton(
                        onPressed: _hasAgreedToTerms
                            ? () {
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
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasAgreedToTerms ? _electricBlue : _charcoal,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _charcoal,
                          disabledForegroundColor: Colors.white24,
                          minimumSize: const Size(double.infinity, 60),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.translate('continue'),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _hasAgreedToTerms ? Colors.white : Colors.white24,
                            fontWeight: FontWeight.w900,
                            fontSize: 16, // Further reduced from 18
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20), // Reduced icon size
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 16, // Reduced from 18
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                  fontSize: 12, // Reduced from 13
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
