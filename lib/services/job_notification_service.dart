import 'package:flutter/foundation.dart';
import 'package:cargo_app/services/cloud_function_service.dart' as notification_service;
import 'package:cargo_app/services/notification_store_service.dart';
import 'package:cargo_app/core/repositories/user_repository.dart';

class JobNotificationService {
  static Future<void> notifyJobStatus({
    required String recipientId,
    required String status,
    required String bookingId,
  }) async {
    debugPrint('🔔 [JobNotification] Notifying recipientId=$recipientId status=$status bookingId=$bookingId');

    try {
      final userRepo = FirebaseUserRepository();
      final recipient = await userRepo.getUserById(recipientId);

      if (recipient == null) {
        debugPrint('⚠️  [JobNotification] Recipient not found in Firestore for uid=$recipientId');
        return;
      }

      final fcmToken = recipient.fcmToken;
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️  [JobNotification] No fcmToken on user $recipientId — they must log out and log back in');
        return;
      }

      debugPrint('🔑 [JobNotification] Got fcmToken for $recipientId: ${fcmToken.substring(0, 20)}...');

      final title = _titleFor(status);
      final body = _bodyFor(status, bookingId);

      await Future.wait([
        notification_service.NotificationService.sendNotificationToUser(
          {'token': fcmToken, 'title': title, 'body': body},
          data: {'type': 'job', 'bookingId': bookingId, 'status': status},
        ),
        NotificationStoreService.storeNotification(
          recipientId: recipientId,
          title: title,
          body: body,
          type: 'job',
          bookingId: bookingId,
        ),
      ]);

      debugPrint('✅ [JobNotification] Notification dispatched for $recipientId');
    } catch (e) {
      debugPrint('❌ [JobNotification] Error: $e');
    }
  }

  static String _titleFor(String status) {
    switch (status) {
      case 'assigned': return 'New Job Assigned';
      case 'accepted': return 'Job Accepted';
      case 'declined': return 'Job Declined';
      case 'completed': return 'Job Completed';
      case 'cancelled': return 'Job Cancelled';
      default: return 'Job Update';
    }
  }

  static String _bodyFor(String status, String bookingId) {
    switch (status) {
      case 'assigned': return 'You have been assigned a new delivery job.';
      case 'accepted': return 'A driver has accepted your delivery request.';
      case 'declined': return 'A driver has declined your delivery request.';
      case 'completed': return 'Your delivery has been completed successfully.';
      case 'cancelled': return 'A job has been cancelled.';
      default: return 'Your job status has been updated.';
    }
  }
}
