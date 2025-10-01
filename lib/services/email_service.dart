import 'dart:convert';
import 'package:http/http.dart' as http;

/// EmailJS service for sending uniform request notifications
class EmailService {
  // ⚡ Update these with your actual EmailJS IDs
  static const String serviceId = 'service_8hwyvbt';
  static const String templateId = 'template_nyx8quh';
  static const String publicKey  = '_VxrLuVeFMOAXs46e';

  /// Sends a uniform request email to the admin
  static Future<bool> sendUniformRequestEmail({
    required String studentNumber,
    required String studentName,
    required String gender,
    required String course,
    required String size,
    required String toEmail,          // recipient email address
    List<int>? qrCodeBytes,           // optional QR image bytes
  }) async {
    try {
      final qrBase64 = qrCodeBytes != null ? base64Encode(qrCodeBytes) : '';

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            // ✅ MUST match template variable names exactly
            'to_email': toEmail,
            'student_number': studentNumber,
            'student_name': studentName,
            'gender': gender,
            'course': course,
            'size': size,
            'qr_code': qrBase64,
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Email sent successfully');
        return true;
      } else {
        print('❌ EmailJS failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ EmailJS exception: $e');
      return false;
    }
  }
}
