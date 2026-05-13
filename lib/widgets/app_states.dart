import 'package:flutter/material.dart';

class AppLoading extends StatelessWidget {
  final String? message;
  const AppLoading({this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ]
        ],
      ),
    );
  }
}

class AppError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AppError({required this.message, this.onRetry, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Oops!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ]
        ],
      ),
    );
  }
}

class AppEmpty extends StatelessWidget {
  final String message;
  final IconData icon;
  const AppEmpty({required this.message, this.icon = Icons.inbox, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
