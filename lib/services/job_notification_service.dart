import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cargo_app/services/cloud_function_service.dart';

class JobNotificationService {
  static Future<void> notifyJobStatus({
    required String recipientId,
    required String status,
    required String bookingId,
  }) async {
    if (recipientId.isEmpty) return;

    final content = _buildContent(status);

    // Persist to Firestore so the user can view notification history.
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(recipientId)
          .collection('items')
          .add({
        'title': content['title'],
        'body': content['body'],
        'type': 'job_status',
        'status': status,
        'bookingId': bookingId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('JobNotificationService: failed to save notification: $e');
    }

    // Send push notification via Cloud Function (best-effort).
    await CloudFunctionService.sendNotificationToUser(
      recipientId,
      {
        'type': 'job_status',
        'status': status,
        'jobId': bookingId,
        'title': content['title']!,
        'body': content['body']!,
      },
    );
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
