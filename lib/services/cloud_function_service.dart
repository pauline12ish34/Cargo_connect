import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  // After deploying to Render, replace this with your Render URL, e.g.:
  // 'https://cargolink-notifications.onrender.com/send-notification'
  static const String _backendUrl = 'https://cargolink-notifications.onrender.com/send-notification';
  static const String _apiKey = 'super-secret-api-key-2026';

  static Future<void> sendNotificationToUser(Map<String, String> payload) async {
    debugPrint('📤 [Notification] Sending to backend: $_backendUrl');
    debugPrint('📤 [Notification] Payload: $payload');

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        debugPrint('✅ [Notification] Sent successfully: ${response.body}');
      } else {
        debugPrint('❌ [Notification] Backend error ${response.statusCode}: ${response.body}');
        throw Exception('Backend returned ${response.statusCode}: ${response.body}');
      }
    } on Exception catch (e) {
      debugPrint('❌ [Notification] Failed to reach backend: $e');
      rethrow;
    }
  }
}
