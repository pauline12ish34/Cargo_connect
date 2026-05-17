import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize(BuildContext context) async {
    // Request permissions (especially for iOS)
    await _messaging.requestPermission();


    // Handle foreground messages with custom logic
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      String displayMessage = 'You have a new notification';
      final data = message.data;

      if (data.isNotEmpty && data['type'] != null) {
        switch (data['type']) {
          case 'chat':
            displayMessage = data['message'] ?? 'New chat message';
            break;
          case 'job_status':
            final status = data['status'] ?? 'updated';
            displayMessage = 'Job status: $status';
            break;
          case 'profile':
            final action = data['action'] ?? 'updated';
            displayMessage = 'Profile $action';
            break;
          case 'announcement':
            displayMessage = data['message'] ?? 'Announcement';
            break;
          default:
            displayMessage = message.notification?.title ?? 'New Notification';
        }
      } else if (message.notification != null) {
        displayMessage = message.notification!.title ?? 'New Notification';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(displayMessage)),
      );
    });

    // Handle background & terminated messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle navigation or other logic here
    });
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
