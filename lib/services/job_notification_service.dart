import 'package:cargo_app/services/cloud_function_service.dart';

class JobNotificationService {
  static Future<void> notifyJobStatus({
    required String recipientId,
    required String status,
    required String bookingId,
  }) async {
    await CloudFunctionService.sendNotificationToUser(
      recipientId,
      {
        'type': 'job_status',
        'status': status,
        'jobId': bookingId,
      },
    );
  }
}
