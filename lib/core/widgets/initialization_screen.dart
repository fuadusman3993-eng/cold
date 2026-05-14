import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cold/features/onboarding/presentation/screens/onboarding_screen.dart';

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // High-speed 1.2s brand hold for a premium snappy feel
    await Future.delayed(const Duration(milliseconds: 1200));
    
    try {
      // Quick background initialization check
      await Supabase.instance.client
          .from('profiles')
          .select()
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 1));
    } catch (_) {}

    if (mounted) {
      _navigateToOnboarding();
    }
  }

  void _navigateToOnboarding() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // X-style smooth reveal transition
          var curve = Curves.easeOutQuart;
          
          var scaleAnimation = Tween<double>(begin: 1.05, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: curve),
          );
          
          var opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: curve),
          );

          return FadeTransition(
            opacity: opacityAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'C',
          style: TextStyle(
            color: Colors.white,
            fontSize: 100,
            fontWeight: FontWeight.w900,
            fontFamily: 'Inter',
            letterSpacing: -5,
          ),
        ),
      ),
    );
  }
}
