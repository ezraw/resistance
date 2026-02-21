import 'package:flutter/material.dart';

/// Custom page transitions for arcade-style screen changes.
class ArcadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final ArcadeTransition transition;

  ArcadePageRoute({
    required this.page,
    this.transition = ArcadeTransition.slideRight,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: _duration(transition),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Check reduce motion
            if (MediaQuery.of(context).disableAnimations) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            }
            return _buildTransition(transition, animation, child);
          },
        );

  static Duration _duration(ArcadeTransition transition) {
    switch (transition) {
      case ArcadeTransition.slideRight:
        return const Duration(milliseconds: 300);
      case ArcadeTransition.slideUp:
        return const Duration(milliseconds: 400);
      case ArcadeTransition.fadeScale:
        return const Duration(milliseconds: 250);
    }
  }

  static Widget _buildTransition(
    ArcadeTransition transition,
    Animation<double> animation,
    Widget child,
  ) {
    switch (transition) {
      case ArcadeTransition.slideRight:
        // Scan -> Home: slide right + scale 95->100%
        final slideAnimation = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );

      case ArcadeTransition.slideUp:
        // Home -> Summary: slide up + bounce
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.elasticOut));
        return SlideTransition(
          position: slideAnimation,
          child: child,
        );

      case ArcadeTransition.fadeScale:
        // Disconnect: fade + scale down
        final fadeAnimation = CurvedAnimation(parent: animation, curve: Curves.easeIn);
        final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));
        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
    }
  }
}

enum ArcadeTransition {
  slideRight,  // Scan -> Home
  slideUp,     // Home -> Summary
  fadeScale,   // Any -> Disconnect/Scan
}
