/// Email configuration for the uniform request system
/// 
/// IMPORTANT: Before using the email functionality, you need to:
/// 1. Replace the placeholder values below with your actual email settings
/// 2. For Gmail, you'll need to:
///    - Enable 2-factor authentication
///    - Generate an App Password (not your regular password)
///    - Use the App Password in the _password field below
/// 3. Update the recipient email address to your admin email
class EmailConfig {
  // SMTP Server Configuration
  static const String smtpServer = 'smtp.gmail.com';
  static const int smtpPort = 587;
  
  // Email Credentials (REPLACE THESE WITH YOUR ACTUAL VALUES)
  static const String username = 'your-email@gmail.com'; // Replace with your email
  static const String password = 'your-app-password'; // Replace with your app password
  
  // Recipient Configuration
  static const String adminEmail = 'admin@university.edu'; // Replace with actual admin email
  
  // Email Settings
  static const String fromName = 'Uniform Request System';
  static const bool allowInsecure = false;
  static const bool ignoreBadCertificate = true;
}
