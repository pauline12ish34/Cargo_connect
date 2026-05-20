import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notification_store_service.dart';
import 'cloud_function_service.dart';

class JobNotificationService {
  /// Notifies all admin users that a driver has submitted documents for review.
  static Future<void> notifyAdminsPendingVerification(String driverName) async {
    try {
      final admins = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (final doc in admins.docs) {
        final adminId = doc.id;
        const title = 'New Driver Verification Request';
        final body = '$driverName has submitted documents for verification.';

        // In-app notification
        await NotificationStoreService.storeNotification(
          recipientId: adminId,
          title: title,
          body: body,
          type: 'verification',
          bookingId: '',
        );

        // Push notification (best-effort)
        final fcmToken = doc.data()['fcmToken'] as String?;
        if (fcmToken != null && fcmToken.isNotEmpty) {
          try {
            await NotificationService.sendNotificationToUser(
              {'token': fcmToken, 'title': title, 'body': body},
              data: {'type': 'verification'},
            );
          } catch (e) {
            debugPrint('Admin push failed (non-fatal): $e');
          }
        }
      }
    } catch (e) {
      debugPrint('notifyAdminsPendingVerification failed: $e');
    }
  }

  /// Notifies a driver of their verification outcome (approved or rejected).
  static Future<void> notifyDriverVerificationResult({
    required String driverId,
    required String status, // 'verified' or 'rejected'
  }) async {
    final approved = status == 'verified';
    const approvedTitle = 'Verification Approved!';
    const rejectedTitle = 'Verification Rejected';
    const approvedBody =
        'Congratulations! Your account is verified. You can now accept jobs on CargoLink.';
    const rejectedBody =
        'Your verification was not approved. Please update your documents and resubmit.';

    final title = approved ? approvedTitle : rejectedTitle;
    final body = approved ? approvedBody : rejectedBody;

    // In-app notification
    await NotificationStoreService.storeNotification(
      recipientId: driverId,
      title: title,
      body: body,
      type: 'verification',
      bookingId: '',
    );

    // Push notification (best-effort)
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(driverId)
          .get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await NotificationService.sendNotificationToUser(
          {'token': fcmToken, 'title': title, 'body': body},
          data: {'type': 'verification', 'status': status},
        );
      }
    } catch (e) {
      debugPrint('Driver verification push failed (non-fatal): $e');
    }
  }

  static Future<void> notifyJobStatus({
    required String recipientId,
    required String status,
    required String bookingId,
  }) async {
    if (recipientId.isEmpty) return;

    final content = _buildContent(status);

    // Save to Firestore so the in-app bell shows it.
    await NotificationStoreService.storeNotification(
      recipientId: recipientId,
      title: content['title']!,
      body: content['body']!,
      type: 'job',
      bookingId: bookingId,
    );

    // Send push notification via Render backend (best-effort).
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientId)
          .get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await NotificationService.sendNotificationToUser(
          {
            'token': fcmToken,
            'title': content['title']!,
            'body': content['body']!,
          },
          data: {
            'type': 'job',
            'status': status,
            'bookingId': bookingId,
          },
        );
      }
    } catch (e) {
      debugPrint('JobNotificationService: push failed (non-fatal): $e');
    }
  }

  static Map<String, String> _buildContent(String status) {
    switch (status) {
      case 'assigned':
        return {
          'title': 'Job Assigned to You',
          'body': 'A cargo owner has selected you for a delivery job.',
        };
      case 'accepted':
        return {
          'title': 'Driver Accepted Your Job',
          'body': 'A driver has accepted your cargo shipment request.',
        };
      case 'completed':
        return {
          'title': 'Job Completed',
          'body': 'Your delivery job has been marked as completed.',
        };
      case 'cancelled':
        return {
          'title': 'Job Cancelled',
          'body': 'A job you were involved in has been cancelled.',
        };
      default:
        return {
          'title': 'Job Update',
          'body': 'Your job status has been updated.',
        };
    }
  }
}
