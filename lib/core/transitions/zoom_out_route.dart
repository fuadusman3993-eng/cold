import 'package:flutter/material.dart';

class ZoomOutPageRoute extends PageRouteBuilder {
  final Widget page;
  final Duration duration;

  ZoomOutPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 600),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // The "zoom-out" effect for the outgoing screen and reveal for the incoming
            // outgoing screen (secondaryAnimation) zooms out
            // incoming screen (animation) zooms in or reveals
            
            var curve = Curves.easeInOutCubic;
            
            var scaleAnimation = Tween<double>(begin: 1.2, end: 1.0).animate(
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
        );
}
