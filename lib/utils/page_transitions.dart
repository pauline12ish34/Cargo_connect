import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  SlideUpPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation);
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );
}
