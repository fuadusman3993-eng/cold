import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

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
    // 2-second hold for the minimalist brand experience
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      // Background Supabase initialization check
      await Supabase.instance.client
          .from('profiles')
          .select()
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Initialization check skipped: $e');
    }

    if (mounted) {
      _navigateToWelcome();
    }
  }

  void _navigateToWelcome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Hero(
          tag: 'app_logo',
          child: Image.asset(
            'assets/images/logo_c.png',
            width: 100, // Balanced, iconic size
            height: 100,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
