import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static GlobalKey<NavigatorState>? _navigatorKey;
  static GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  /// Initialise FCM: permissions, channel options, foreground listener,
  /// tap-to-navigate listener, and cold-start message handling.
  ///
  /// Call this once in [main()] after Firebase.initializeApp().
  static Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  }) async {
    _navigatorKey = navigatorKey;
    _scaffoldMessengerKey = scaffoldMessengerKey;

    // 1. Request permission (shows a system dialog on iOS; no-op on Android <13)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. On iOS: display FCM notifications as alerts/banners even when the app
    //    is in the foreground (Android handles this through the notification channel
    //    declared in AndroidManifest.xml).
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Foreground messages — show a SnackBar with the notification content.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 4. Background → foreground tap (app was in background, user taps notification).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // 5. Cold-start tap (app was terminated, user taps notification to open it).
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay navigation until the widget tree is ready.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleMessageTap(initialMessage);
      });
    }
  }

  // ── Foreground handler ───────────────────────────────────────────────────────

  static void _handleForegroundMessage(RemoteMessage message) {
    final String displayMessage = _buildDisplayMessage(message);

    _scaffoldMessengerKey?.currentState?.showSnackBar(
      SnackBar(
        content: Text(displayMessage),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _handleMessageTap(message),
        ),
      ),
    );
  }

  // ── Tap-to-navigate ──────────────────────────────────────────────────────────

  static void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    switch (type) {
      case 'chat':
        // Navigate to home; the chat screen is opened from booking details.
        navigator.pushNamedAndRemoveUntil('/home', (route) => false);
        break;
      case 'job_status':
        navigator.pushNamedAndRemoveUntil('/home', (route) => false);
        break;
      default:
        navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static String _buildDisplayMessage(RemoteMessage message) {
    final data = message.data;
    if (data.isNotEmpty && data['type'] != null) {
      switch (data['type']) {
        case 'chat':
          return data['message'] as String? ?? 'New chat message';
        case 'job_status':
          final status = data['status'] as String? ?? 'updated';
          return 'Job status: $status';
        case 'profile':
          final action = data['action'] as String? ?? 'updated';
          return 'Profile $action';
        case 'announcement':
          return data['message'] as String? ?? 'Announcement';
        default:
          return message.notification?.title ?? 'New Notification';
      }
    }
    return message.notification?.title ?? 'New Notification';
  }

  // ── Token ────────────────────────────────────────────────────────────────────

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
