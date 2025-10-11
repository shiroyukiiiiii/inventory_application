import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailJsService {
  static Future<void> sendAdminRegistrationEmail({
    required String toEmail,
    required String toName,
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': 'template_admin_registration', // <-- Set your admin registration template ID here
        'user_id': userId,
        'template_params': {
          'to_email': toEmail,
          'to_name': toName,
          'username': username,
          'password': password,
        }
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send admin registration email: \\${response.body}');
    }
  }
  static const String serviceId = 'service_rhy5ula';
  static const String templateId = 'template_es6tz3k';
  static const String userId = 'fkjnejUTrQGSFyntI';

  static Future<void> sendApprovalEmail({
    required String toEmail,
    required String toName,
    required String studentNumber,
    required String studentName,
    required String gender,
    required String course,
    required String size,
    required String qrCode,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost', // or your deployed domain
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'to_email': toEmail,
          'to_name': toName,
          'student_number': studentNumber,
          'student_name': studentName,
          'gender': gender,
          'course': course,
          'size': size,
          'qr_code': qrCode,
        }
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send approval email: ${response.body}');
    }
  }
}
