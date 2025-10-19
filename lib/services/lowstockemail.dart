import 'dart:convert';
import 'package:http/http.dart' as http;

/// EmailJS service for sending low stock alert notifications
class LowStockEmailService {
  // ⚡ Update these with your actual EmailJS credentials
  static const String serviceId = 'service_tsuxyxb'; // 🔹 Your EmailJS Service ID
  static const String templateId = 'template_ec46u9x'; // 🔹 Your Low Stock Template ID
  static const String publicKey = 'X-Oh--OdxBEe22U8y'; // 🔹 Your EmailJS Public Key

  /// Sends a low stock alert email to the admin
  static Future<bool> sendLowStockAlert({
    required String course,
    required String gender,
    required String size,
    required int remainingStock,
    required String toEmail, // recipient email address (admin)
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            // ✅ Must match variable names in your EmailJS template
            'to_email': toEmail,
            'course': course,
            'gender': gender,
            'size': size,
            'remaining_stock': remainingStock.toString(),
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Low stock alert email sent successfully');
        return true;
      } else {
        print('❌ Failed to send low stock email: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ EmailJS exception: $e');
      return false;
    }
  }
}
