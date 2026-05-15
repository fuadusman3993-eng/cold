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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    if (_hasAgreedToTerms) {
      _pulseController.stop();
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. ISOLATED BLUR LAYER (Map + Features)
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

          // 2. UNBLURRED OVERLAY LAYER
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: const LanguageSelector(),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? size.width * 0.2 : 32.0,
                0,
                isDesktop ? size.width * 0.2 : 32.0,
                32.0,
              ),
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
                          height: 18,
                          width: 18,
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.translate('terms_agreement'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _hasAgreedToTerms ? Colors.white : Colors.white60,
                            fontSize: isDesktop ? 12 : 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
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
                              // Automated Upward Scroll Transition (TikTok Style)
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      const LoginScreen(),
                                  transitionsBuilder:
                                      (context, animation, secondaryAnimation, child) {
                                    const begin = Offset(0.0, 1.0); // Start from bottom
                                    const end = Offset.zero;
                                    const curve = Curves.fastOutSlowIn;
                                    
                                    var tween = Tween(begin: begin, end: end)
                                        .chain(CurveTween(curve: curve));
                                    
                                    // Current page slides up while new page follows
                                    return SlideTransition(
                                      position: animation.drive(tween),
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(milliseconds: 500),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasAgreedToTerms ? _electricBlue : _charcoal,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _charcoal,
                        disabledForegroundColor: Colors.white24,
                        minimumSize: Size(double.infinity, isDesktop ? 64 : 56),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l10n.translate('continue'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: _hasAgreedToTerms ? Colors.white : Colors.white24,
                          fontWeight: FontWeight.w900,
                          fontSize: isDesktop ? 18 : 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, Size screenSize) {
    final theme = Theme.of(context);
    final isDesktop = screenSize.width > 900;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isDesktop ? 10 : 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
          ),
          child: Icon(icon, color: Colors.white, size: isDesktop ? 24 : 18),
        ),
        SizedBox(width: isDesktop ? 20 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: isDesktop ? 16 : 14,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                  fontSize: isDesktop ? 12 : 10,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
