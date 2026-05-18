import 'package:cargo_app/services/cloud_function_service.dart' as notification_service;
import 'package:cargo_app/core/repositories/user_repository.dart';

class JobNotificationService {
  static Future<void> notifyJobStatus({
    required String recipientId,
    required String status,
    required String bookingId,
  }) async {
    try {
      final userRepo = FirebaseUserRepository();
      final recipient = await userRepo.getUserById(recipientId);
      final fcmToken = recipient?.fcmToken;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await notification_service.NotificationService.sendNotificationToUser({
          'token': fcmToken,
          'title': 'Job Status Update',
          'body': 'Job $bookingId status: $status',
        });
      }
    } catch (_) {}
  }
}
