import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class CloudinaryService {
  // ── Fill these in after setting up your free Cloudinary account ──────────
  static const String _cloudName = 'dziad792p';
  static const String _uploadPreset = 'cargolink_uploads';
  // ─────────────────────────────────────────────────────────────────────────

  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Uploads [file] to Cloudinary and returns the secure URL.
  /// [folder] organises files inside your Cloudinary media library.
  static Future<String> uploadFile(File file, {String folder = 'cargolink'}) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
    request.fields['upload_preset'] = _uploadPreset;
    request.fields['folder'] = folder;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final url = json['secure_url'] as String?;
      if (url != null && url.isNotEmpty) {
        debugPrint('☁️  [Cloudinary] Uploaded: $url');
        return url;
      }
    }
    debugPrint('☁️  [Cloudinary] Error ${response.statusCode}: ${response.body}');
    throw Exception('Cloudinary upload failed (${response.statusCode})');
  }
}
