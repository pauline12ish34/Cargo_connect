import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants.dart';

// ─── Snackbar Helpers ─────────────────────────────────────────────────────────

class AppSnackbar {
  AppSnackbar._();

  static void showError(BuildContext context, String message) {
    _show(context, message: message, icon: Icons.error_outline_rounded, background: const Color(0xFFEF4444));
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, icon: Icons.check_circle_outline_rounded, background: primaryGreen);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message: message, icon: Icons.info_outline_rounded, background: const Color(0xFF3B82F6));
  }

  static void _show(BuildContext context, {required String message, required IconData icon, required Color background}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
        ]),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ));
  }
}

// ─── Loading State ────────────────────────────────────────────────────────────

class AppLoading extends StatelessWidget {
  final String? message;
  const AppLoading({this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(primaryGreen)),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ],
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class AppError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AppError({required this.message, this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: Colors.white),
              ),
            ],
          ],
        ).animate().fade(duration: 300.ms),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class AppEmpty extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const AppEmpty({
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ).animate().fade(duration: 400.ms).slideY(begin: 0.06),
      ),
    );
  }
}

// ─── Skeleton Loader ──────────────────────────────────────────────────────────

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({this.width, this.height = 16, this.borderRadius = 8, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(borderRadius)),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.grey.shade100);
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const SkeletonBox(width: 40, height: 40, borderRadius: 20),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SkeletonBox(width: 120, height: 14),
                SizedBox(height: 6),
                SkeletonBox(width: 80, height: 12),
              ])),
            ]),
            const SizedBox(height: 12),
            const SkeletonBox(height: 12),
            const SizedBox(height: 6),
            const SkeletonBox(width: 200, height: 12),
          ],
        ),
      ),
    );
  }
}
