import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedNavigator {
  /// Navigates to a new route using a lightweight, hardware-accelerated FadeTransition.
  /// Executes [onNavigateOut] immediately (e.g., to pause videos) before pushing.
  static Future<T?> mapsTo<T>(
    BuildContext context, 
    Widget destination, {
    VoidCallback? onNavigateOut,
  }) {
    // 1. Auto-Pause on Navigate
    if (onNavigateOut != null) {
      onNavigateOut();
    }

    // 2. Hardware-Accelerated Transition (Fade)
    return Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  /// Asynchronously launches an external URL outside the main UI rendering thread.
  static Future<void> launchExternalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    
    // Ensure async link handling doesn't block the UI thread during taps
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}
