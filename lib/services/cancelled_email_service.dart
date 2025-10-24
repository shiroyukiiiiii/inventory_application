import 'dart:convert';
import 'package:http/http.dart' as http;

class CancelledEmailService {
  // ⚙️ Replace these with your actual EmailJS credentials
  static const String serviceId = 'service_tsuxyxb'; // Your EmailJS service ID
  static const String templateId = 'template_bejmbny'; // Your cancellation email template ID
  static const String userId = 'X-Oh--OdxBEe22U8y'; // Your EmailJS public key

  // 📧 Function to send cancellation email
  static Future<bool> sendCancelledEmail({
    required String studentNumber,
    required String studentName,
    required String course,
    required String gender,
    required String size,
    required String orderQuantity,
    required String toEmail,
  }) async {
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'template_params': {
            'to_email': toEmail,
            'student_number': studentNumber,
            'student_name': studentName,
            'course': course,
            'gender': gender,
            'size': size,
            'order_quantity': orderQuantity,
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Cancellation email sent to $toEmail');
        return true;
      } else {
        print('❌ Failed to send email: ${response.body}');
        return false;
      }
    } catch (e) {
      print('⚠️ Error sending email: $e');
      return false;
    }
  }
}
