import 'dart:convert';
import 'package:http/http.dart' as http;

class BrevoEmailService {
  static const String _apiUrl = "https://api.brevo.com/v3/smtp/email";
  static const String _apiKey = "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"; // 🔑 Replace this!

  static Future<void> sendAdminRegistrationEmail({
    required String toEmail,
    required String toName,
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'accept': 'application/json',
        'api-key': _apiKey,
        'content-type': 'application/json',
      },
      body: jsonEncode({
        "sender": {
          "name": "SIASU Admin System",
          "email": "christian.karl.m.cortes@gmail.com" // ✅ Must be verified in Brevo
        },
        "to": [
          {"email": toEmail, "name": toName}
        ],
        "subject": "Your SIASU Admin Account Has Been Created 🎉",
        "htmlContent": """
          <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6;">
            <h2 style="color: #1a73e8;">Welcome, $toName!</h2>
            <p>Your admin account has been successfully created in <b>SIASU</b>.</p>

            <h3>Account Details</h3>
            <table style="border-collapse: collapse;">
              <tr><td><b>Email:</b></td><td> $toEmail </td></tr>
              <tr><td><b>Username:</b></td><td> $username </td></tr>
              <tr><td><b>Password:</b></td><td> $password </td></tr>
            </table>

            <br>
            <p>You can now log in to the SIASU Admin Portal and start managing requests.</p>
            <p style="color: #777;">If you didn’t request this account, please contact the system administrator.</p>

            <br><hr>
            <p style="font-size: 12px; color: gray;">&copy; 2025 SIASU System | This is an automated email.</p>
          </body>
          </html>
        """
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send email: ${response.body}');
    }
  }
}
