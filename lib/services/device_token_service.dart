import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'push_notification_service.dart';

class DeviceTokenService {
  static Future<void> saveDeviceToken([String? token, String? userId]) async {
    final user = FirebaseAuth.instance.currentUser;
    final resolvedUserId = userId ?? user?.uid;
    final resolvedToken = token ?? await PushNotificationService.getToken();

    if (resolvedUserId == null) {
      debugPrint('⚠️  [DeviceToken] No logged-in user — skipping token save');
      return;
    }
    if (resolvedToken == null) {
      debugPrint('⚠️  [DeviceToken] Could not get FCM token from device');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(resolvedUserId)
          .update({'fcmToken': resolvedToken});
      debugPrint('✅ [DeviceToken] Saved fcmToken for $resolvedUserId: ${resolvedToken.substring(0, 20)}...');
    } catch (e) {
      debugPrint('❌ [DeviceToken] Failed to save fcmToken: $e');
    }
  }

  static Future<void> clearDeviceToken(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': FieldValue.delete()});
      debugPrint('✅ [DeviceToken] Cleared fcmToken for $userId');
    } catch (e) {
      debugPrint('❌ [DeviceToken] Failed to clear fcmToken: $e');
    }
  }

  static void listenForTokenRefresh() {
    PushNotificationService.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('🔄 [DeviceToken] Token refreshed — saving new token');
        await saveDeviceToken(newToken, user.uid);
      }
    });
  }
}
