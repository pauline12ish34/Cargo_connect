import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Flexible(
                flex: 4,
                child: Image.asset(
                  "assets/images/welcome.png",
                  height: 280,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.image_not_supported, size: 120, color: Colors.grey),
                )
                .animate()
                .fade(duration: 800.ms)
                .scale(delay: 100.ms, duration: 600.ms, curve: Curves.easeOutBack),
              ),
              const SizedBox(height: 40),
              Text(
                "Welcome to CargoLink",
                style: welcomeTitleStyle.copyWith(color: cs.onSurface),
                textAlign: TextAlign.center,
              )
              .animate()
              .fade(delay: 400.ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 12),
              Text(
                "The smartest way to connect cargo owners\nwith reliable drivers across the country.",
                style: welcomeSubtitleStyle.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              )
              .animate()
              .fade(delay: 600.ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  style: primaryButtonStyle.copyWith(
                    elevation: WidgetStateProperty.all(2),
                    shadowColor: WidgetStateProperty.all(appGreen.withOpacity(0.5)),
                  ),
                  child: const Text("CREATE ACCOUNT", style: TextStyle(color: Colors.white, letterSpacing: 1.2)),
                ),
              )
              .animate()
              .fade(delay: 800.ms, duration: 500.ms)
              .slideX(begin: -0.1, end: 0),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: outlineButtonStyle.copyWith(
                    side: WidgetStateProperty.all(const BorderSide(color: appGreen, width: 1.5)),
                  ),
                  child: const Text("LOGIN", style: TextStyle(color: appGreen, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              )
              .animate()
              .fade(delay: 1000.ms, duration: 500.ms)
              .slideX(begin: 0.1, end: 0),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
