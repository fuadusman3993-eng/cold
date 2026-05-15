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

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _hasAgreedToTerms = false;
  static const Color _electricBlue = Color(0xFF2196F3); // Official Cold Accent
  static const Color _charcoal = Color(0xFF1A1A1A); // Disabled State

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
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
              // 1. Top Section: Blurred/Dimmed by default
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 10.0, end: _hasAgreedToTerms ? 0.0 : 10.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, blurValue, child) {
                    return ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 600),
                        opacity: _hasAgreedToTerms ? 1.0 : 0.5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            // Map Visual
                            Image.asset(
                              'assets/images/world_map.png',
                              height: 320,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 240,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 60),
                            // Features
                            _buildFeatureItem(
                              Icons.psychology_outlined,
                              l10n.translate('islamic_ai_title'),
                              l10n.translate('islamic_ai_subtitle'),
                            ),
                            const SizedBox(height: 32),
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
              
              // 2. Bottom Section: Always visible (Unblurred)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    // Agreement Checkbox Row
                    Row(
                      children: [
                        SizedBox(
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.translate('terms_agreement'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _hasAgreedToTerms ? Colors.white : Colors.white60,
                              fontWeight: FontWeight.w400,
                              fontSize: 11,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Action Button with State Transitions
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _hasAgreedToTerms
                            ? [
                                BoxShadow(
                                  color: _electricBlue.withOpacity(0.3),
                                  blurRadius: 20,
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
                          minimumSize: const Size(double.infinity, 64),
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
                            fontSize: 18,
                            letterSpacing: 1.2,
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 18,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
