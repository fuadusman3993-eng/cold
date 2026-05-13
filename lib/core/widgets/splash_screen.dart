import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../transitions/zoom_out_route.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // User requested 800ms
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    // Start measuring time
    final stopwatch = Stopwatch()..start();

    // Perform background initialization (Supabase)
    try {
      await Supabase.instance.client
          .from('profiles')
          .select()
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Initialization check skipped or failed: $e');
    }

    // Ensure at least 2 seconds total splash time
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 2000) {
      await Future.delayed(Duration(milliseconds: 2000 - elapsed));
    }

    if (mounted) {
      _navigateToOnboarding();
    }
  }

  void _navigateToOnboarding() {
    Navigator.of(context).pushReplacement(
      ZoomOutPageRoute(
        page: const OnboardingScreen(),
        duration: const Duration(milliseconds: 600), // User requested 600ms
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure black as requested
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Hero(
            tag: 'app_logo',
            child: Image.asset(
              'assets/images/logo_c.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback in case image fails to load
                return const Text(
                  'C',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
