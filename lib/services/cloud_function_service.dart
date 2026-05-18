
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  // Replace with your FastAPI backend URL
  static const String backendUrl = 'http://172.31.28.160:8000/send-notification';

  static const String apiKey = 'super-secret-api-key-2026'; // Set this to match your backend

  static Future<void> sendNotificationToUser(Map<String, String> payload) async {
    final response = await http.post(
      Uri.parse(backendUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      },
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send notification: ${response.body}');
    }
  }
}
