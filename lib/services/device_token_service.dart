import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'push_notification_service.dart';

class DeviceTokenService {
  /// Call this after login/signup and on app start
  static Future<void> saveDeviceToken([String? token, String? userId]) async {
    final user = FirebaseAuth.instance.currentUser;
    final resolvedUserId = userId ?? user?.uid;
    final resolvedToken = token ?? await PushNotificationService.getToken();
    print('Device token: ${resolvedToken ?? 'null'}');
    if (resolvedUserId != null && resolvedToken != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(resolvedUserId)
          .update({'fcmToken': resolvedToken});
    } else {
      print('Failed to get device token or user id. User: '
          '${resolvedUserId ?? 'null'}, Token: ${resolvedToken ?? 'null'}');
    }
  }

  /// Listen for token refresh and update Firestore
  static void listenForTokenRefresh() {
    PushNotificationService.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await saveDeviceToken(newToken, user.uid);
      }
    });
  }

  // (Removed duplicate saveDeviceToken)
}
