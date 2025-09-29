import 'dart:io';
import 'dart:typed_data';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config/email_config.dart';

class EmailService {

  /// Sends a uniform request confirmation email with QR code attachment
  static Future<bool> sendUniformRequestEmail({
    required String studentNumber,
    required String studentName,
    required String gender,
    required String course,
    required String size,
    required Uint8List qrCodeBytes,
  }) async {
    try {
      // Create SMTP server configuration
      final smtpServer = SmtpServer(
        EmailConfig.smtpServer,
        port: EmailConfig.smtpPort,
        username: EmailConfig.username,
        password: EmailConfig.password,
        allowInsecure: EmailConfig.allowInsecure,
        ignoreBadCertificate: EmailConfig.ignoreBadCertificate,
      );

      // Create temporary file for QR code
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/qr_$studentNumber.png');
      await tempFile.writeAsBytes(qrCodeBytes);

      // Create email message
      final message = Message()
        ..from = Address(EmailConfig.username, EmailConfig.fromName)
        ..recipients.add(EmailConfig.adminEmail)
        ..subject = 'New Uniform Request - Student: $studentNumber'
        ..html = _createEmailBody(studentNumber, studentName, gender, course, size)
        ..attachments = [
          FileAttachment(
            tempFile,
            fileName: 'student_qr_$studentNumber.png',
            contentType: 'image/png',
          ),
        ];

      // Send the email
      final sendReport = await send(message, smtpServer);
      print('Email sent: ${sendReport.toString()}');
      
      // Clean up temporary file
      try {
        await tempFile.delete();
      } catch (e) {
        print('Warning: Could not delete temporary file: $e');
      }
      
      return true;
    } catch (e) {
      print('Failed to send email: $e');
      return false;
    }
  }

  /// Creates the HTML body for the email
  static String _createEmailBody(
    String studentNumber,
    String studentName,
    String gender,
    String course,
    String size,
  ) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Uniform Request Confirmation</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
            .content { margin: 20px 0; }
            .qr-section { text-align: center; margin: 20px 0; }
            .details { background-color: #f9f9f9; padding: 15px; border-radius: 5px; }
            .footer { margin-top: 30px; font-size: 12px; color: #666; }
        </style>
    </head>
    <body>
        <div class="header">
            <h2>🎓 Uniform Request Confirmation</h2>
        </div>
        
        <div class="content">
            <p>Dear Admin,</p>
            <p>A new uniform request has been submitted with the following details:</p>
            
            <div class="details">
                <h3>Student Information:</h3>
                <p><strong>Student Number:</strong> $studentNumber</p>
                <p><strong>Student Name:</strong> $studentName</p>
                <p><strong>Gender:</strong> $gender</p>
                <p><strong>Course:</strong> $course</p>
                <p><strong>Uniform Size:</strong> $size</p>
            </div>
            
            <div class="qr-section">
                <h3>Student QR Code:</h3>
                <p>The QR code for student number <strong>$studentNumber</strong> is attached to this email.</p>
                <p>This QR code can be used for quick identification and verification purposes.</p>
            </div>
        </div>
        
        <div class="footer">
            <p>This is an automated message from the Uniform Request System.</p>
            <p>Please process this request accordingly.</p>
        </div>
    </body>
    </html>
    ''';
  }

  /// Sends a simple text email (fallback option)
  static Future<bool> sendSimpleEmail({
    required String studentNumber,
    required String studentName,
    required String gender,
    required String course,
    required String size,
  }) async {
    try {
      final smtpServer = SmtpServer(
        EmailConfig.smtpServer,
        port: EmailConfig.smtpPort,
        username: EmailConfig.username,
        password: EmailConfig.password,
        allowInsecure: EmailConfig.allowInsecure,
        ignoreBadCertificate: EmailConfig.ignoreBadCertificate,
      );

      final message = Message()
        ..from = Address(EmailConfig.username, EmailConfig.fromName)
        ..recipients.add(EmailConfig.adminEmail)
        ..subject = 'New Uniform Request - Student: $studentNumber'
        ..text = '''
New Uniform Request Submitted

Student Number: $studentNumber
Student Name: $studentName
Gender: $gender
Course: $course
Uniform Size: $size

Please process this request accordingly.

This is an automated message from the Uniform Request System.
        ''';

      final sendReport = await send(message, smtpServer);
      print('Email sent: ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('Failed to send email: $e');
      return false;
    }
  }
}
