# Email Setup Instructions

This document explains how to configure the email functionality for the uniform request system.

## Prerequisites

1. **Gmail Account**: You'll need a Gmail account to send emails
2. **App Password**: Gmail requires an App Password for third-party applications

## Step-by-Step Setup

### 1. Enable 2-Factor Authentication

1. Go to your [Google Account settings](https://myaccount.google.com/)
2. Navigate to **Security**
3. Under "Signing in to Google", click **2-Step Verification**
4. Follow the prompts to enable 2-factor authentication

### 2. Generate an App Password

1. In your Google Account settings, go to **Security**
2. Under "Signing in to Google", click **App passwords**
3. Select **Mail** as the app
4. Select **Other (custom name)** as the device
5. Enter "Uniform Request System" as the name
6. Click **Generate**
7. **Copy the 16-character password** (you'll need this for the configuration)

### 3. Configure the Application

1. Open `lib/config/email_config.dart`
2. Replace the placeholder values:

```dart
// Replace these with your actual values
static const String username = 'your-email@gmail.com'; // Your Gmail address
static const String password = 'your-app-password'; // The 16-character app password
static const String adminEmail = 'admin@university.edu'; // Where to send notifications
```

### 4. Example Configuration

```dart
class EmailConfig {
  static const String smtpServer = 'smtp.gmail.com';
  static const int smtpPort = 587;
  
  // Your actual Gmail credentials
  static const String username = 'university.system@gmail.com';
  static const String password = 'abcd efgh ijkl mnop'; // Your app password
  
  // Admin email to receive notifications
  static const String adminEmail = 'admin@university.edu';
  
  static const String fromName = 'Uniform Request System';
  static const bool allowInsecure = false;
  static const bool ignoreBadCertificate = true;
}
```

## Features

Once configured, the system will:

1. **Generate QR Codes**: Create QR codes from student numbers
2. **Send Email Notifications**: Automatically send emails when uniform requests are submitted
3. **Attach QR Codes**: Include the student's QR code as an image attachment
4. **Professional Email Format**: Send well-formatted HTML emails with all request details

## Email Content

The system sends emails containing:

- Student information (name, number, course, gender)
- Uniform size requested
- QR code attachment for quick identification
- Professional HTML formatting
- Timestamp of the request

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Ensure 2-factor authentication is enabled
   - Verify you're using the App Password, not your regular password
   - Check that the App Password is correctly copied (no spaces)

2. **Connection Issues**
   - Verify your internet connection
   - Check that Gmail SMTP is not blocked by your firewall
   - Ensure the SMTP settings are correct (smtp.gmail.com, port 587)

3. **Email Not Received**
   - Check the admin email address is correct
   - Look in spam/junk folders
   - Verify the sender email is not blocked

### Testing

To test the email functionality:

1. Submit a uniform request through the app
2. Check the console for any error messages
3. Verify the email is received at the admin address
4. Confirm the QR code attachment is present

## Security Notes

- Never commit your actual email credentials to version control
- Use environment variables or secure configuration files in production
- Regularly rotate your App Passwords
- Monitor email sending for any suspicious activity

## Support

If you encounter issues:

1. Check the console logs for error messages
2. Verify all configuration values are correct
3. Test with a simple email first before using the full system
4. Ensure all dependencies are properly installed (`flutter pub get`)
