import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailJsService {
  static const String serviceId = 'service_8hwyvbt';
  static const String templateId = 'template_ae41hfa';
  static const String userId = '_VxrLuVeFMOAXs46e';

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
