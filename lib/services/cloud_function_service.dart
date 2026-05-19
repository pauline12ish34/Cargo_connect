import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class CloudFunctionService {
  /// Sends a push notification to [toUid] via the `sendNotification` Cloud Function.
  ///
  /// Failures are logged and swallowed so callers are not forced to catch
  /// notification errors as fatal. Returns [true] on success, [false] on failure.
  static Future<bool> sendNotificationToUser(
    String toUid,
    Map<String, String> payload,
  ) async {
    if (toUid.isEmpty) {
      debugPrint('CloudFunctionService: skipping notification — toUid is empty');
      return false;
    }

    try {
      final HttpsCallable callable = FirebaseFunctions.instance
          .httpsCallable(
            'sendNotification',
            options: HttpsCallableOptions(
              timeout: const Duration(seconds: 10),
            ),
          );
      await callable.call({'toUid': toUid, 'payload': payload});
      return true;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'CloudFunctionService: sendNotification failed '
        '[${e.code}] ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('CloudFunctionService: sendNotification error: $e');
      return false;
    }
  }
}
