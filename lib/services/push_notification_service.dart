import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cargo_app/core/repositories/booking_repository.dart';
import 'package:cargo_app/features/chat/chat_screen.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static GlobalKey<NavigatorState>? _navigatorKey;

  static const _channel = AndroidNotificationChannel(
    'cargolink_high',
    'CargoLink Notifications',
    description: 'Job updates and chat messages',
    importance: Importance.high,
  );

  static Future<void> initialize(
    GlobalKey<ScaffoldMessengerState> messengerKey,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    if (_initialized) return;
    _initialized = true;
    _navigatorKey = navigatorKey;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // User tapped a foreground local notification
        if (response.payload != null) {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          _navigateFromData(data);
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Foreground: show popup and store data in payload for tap handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });

    // Background: user tapped notification while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateFromData(message.data);
    });

    // Killed: app opened from a notification tap
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay to let the widget tree build first
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateFromData(initialMessage.data);
      });
    }
  }

  static Future<void> _navigateFromData(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    final bookingId = data['bookingId'] as String?;
    if (type == null || bookingId == null) return;

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    try {
      final booking = await FirebaseBookingRepository().getBookingById(bookingId);
      if (booking == null) return;

      if (type == 'chat') {
        final senderName = data['senderName'] as String? ?? 'User';
        navigator.push(MaterialPageRoute(
          builder: (_) => ChatScreen(
            booking: booking,
            otherUserName: senderName,
          ),
        ));
      } else if (type == 'job') {
        // Navigate to the home screen's correct tab
        // Driver: go to Available Jobs tab (index 1) for assigned jobs
        //         go to My Jobs tab (index 2) for accepted/completed
        final status = data['status'] as String? ?? '';
        navigator.pushNamedAndRemoveUntil('/home', (route) => false,
            arguments: {'tab': status == 'assigned' ? 1 : 2});
      }
    } catch (e) {
      debugPrint('❌ [PushNotification] Navigation failed: $e');
    }
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
