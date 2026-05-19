import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Show splash for at least 2 seconds so animations can play
    final minSplashFuture = Future.delayed(const Duration(milliseconds: 2000));

    // Wait for the first Firebase auth state event (resolves immediately if
    // Firebase already has a cached credential, or after network round-trip
    // if the session needs refreshing). This is more reliable than a fixed
    // delay because it doesn't race against the auth stream.
    final User? firebaseUser = await FirebaseAuth.instance
        .authStateChanges()
        .first
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );

    await minSplashFuture; // ensure minimum display time

    if (!mounted) return;

    if (firebaseUser != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [Colors.white, const Color(0xFFE1F3ED)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/splash-illustration.png',
              width: 280,
              height: 280,
              fit: BoxFit.contain,
            )
                .animate()
                .fade(duration: 800.ms)
                .scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 20),
            Image.asset(
              'assets/images/cargolink-logo.png',
              width: 180,
              height: 60,
              fit: BoxFit.contain,
            )
                .animate(delay: 600.ms)
                .fade(duration: 500.ms)
                .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
            const SizedBox(height: 60),
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF08914D)),
            )
                .animate(delay: 1200.ms)
                .fade(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
