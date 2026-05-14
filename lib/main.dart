import 'package:flutter/material.dart';
import 'package:cold/core/theme/app_theme.dart';
import 'package:cold/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  runApp(const ColdApp());
}

class ColdApp extends StatelessWidget {
  const ColdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cold',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const OnboardingScreen(),
    );
  }
}
