import 'package:cloud_functions/cloud_functions.dart';

class CloudFunctionService {
  static Future<void> sendNotificationToUser(String toUid, Map<String, String> payload) async {
    final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendNotification');
    await callable.call({
      'toUid': toUid,
      'payload': payload,
    });
  }
}
