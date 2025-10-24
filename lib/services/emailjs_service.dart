import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailJsService {
  static const String serviceId = 'service_rhy5ula';
  static const String templateId = 'template_es6tz3k';
  static const String userId = 'fkjnejUTrQGSFyntI';
  static const String cancellationTemplateId = 'template_cancel_xyz';

  /// Sends an admin registration email with credentials
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
        'template_id':
            'template_admin_registration', // ✅ Make sure it exists in EmailJS
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
      throw Exception(
          'Failed to send admin registration email: ${response.body}');
    }

    print('✅ Admin registration email sent successfully');
  }

  /// Sends approval email to student when request is approved
  static Future<void> sendApprovalEmail({
    required String toEmail,
    required String toName,
    required String studentNumber,
    required String studentName,
    required String gender,
    required String course,
    required String size,
    required int orderQuantity,
    required String qrCode,
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
        'template_id': templateId, // ✅ existing template for approvals
        'user_id': userId,
        'template_params': {
          'to_email': toEmail,
          'to_name': toName,
          'student_number': studentNumber,
          'student_name': studentName,
          'gender': gender,
          'course': course,
          'size': size,
          'order_quantity': orderQuantity,
          'qr_code': qrCode,
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send approval email: ${response.body}');
    }

    print('✅ Approval email sent successfully');
  }

  /// ✅ Sends cancellation email when an order is cancelled
  static Future<void> sendCancellationEmail({
    required String toEmail,
    required String toName,
    required String studentNumber,
    required String studentName,
    required String gender,
    required String course,
    required String size,
    required int orderQuantity,
    String? reason, // Optional cancellation reason
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
        'template_id': cancellationTemplateId, // ✅ Create this in EmailJS
        'user_id': userId,
        'template_params': {
          'to_email': toEmail,
          'to_name': toName,
          'student_number': studentNumber,
          'student_name': studentName,
          'gender': gender,
          'course': course,
          'size': size,
          'order_quantity': orderQuantity,
          'reason': reason ?? 'Your order has been cancelled by the admin.',
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send cancellation email: ${response.body}');
    }

    print('✅ Cancellation email sent successfully');
  }
}
