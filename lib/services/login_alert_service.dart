// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class LoginAlertService {
  static const String _emailServiceEndpoint = 'https://your-email-service.com/api/send'; // Replace with actual endpoint
  static const String _emailApiKey = 'YOUR_EMAIL_API_KEY'; // Replace with actual API key
  
  static AuthProvider? _authProvider;
  
  /// Initialize login alert service
  static void initialize(AuthProvider authProvider) {
    _authProvider = authProvider;
    
    // Listen for authentication events
    authProvider.addListener(_onAuthStateChanged);
  }
  
  /// Handle authentication state changes
  static void _onAuthStateChanged() {
    final user = _authProvider?.user;
    if (user != null && _authProvider?.isLoggedIn == true) {
      // User just logged in, send login alert
      _sendLoginAlert(user);
    }
  }
  
  /// Send welcome email for first-time users
  static Future<void> sendWelcomeEmail(UserModel user) async {
    try {
      print('LoginAlertService: Sending welcome email to ${user.email}');
      
      final emailData = await _buildWelcomeEmailData(user);
      await _sendEmail(emailData);
      
      print('LoginAlertService: Welcome email sent successfully');
    } catch (e) {
      print('LoginAlertService: Error sending welcome email: $e');
    }
  }
  
  /// Send login alert email
  static Future<void> _sendLoginAlert(UserModel user) async {
    try {
      print('LoginAlertService: Sending login alert to ${user.email}');
      
      final emailData = await _buildLoginAlertEmailData(user);
      await _sendEmail(emailData);
      
      print('LoginAlertService: Login alert sent successfully');
    } catch (e) {
      print('LoginAlertService: Error sending login alert: $e');
    }
  }
  
  /// Send password change alert
  static Future<void> sendPasswordChangeAlert(UserModel user) async {
    try {
      print('LoginAlertService: Sending password change alert to ${user.email}');
      
      final emailData = await _buildPasswordChangeAlertData(user);
      await _sendEmail(emailData);
      
      print('LoginAlertService: Password change alert sent successfully');
    } catch (e) {
      print('LoginAlertService: Error sending password change alert: $e');
    }
  }
  
  /// Send security alert for suspicious activity
  static Future<void> sendSecurityAlert(UserModel user, String alertType, String details) async {
    try {
      print('LoginAlertService: Sending security alert to ${user.email}');
      
      final emailData = await _buildSecurityAlertData(user, alertType, details);
      await _sendEmail(emailData);
      
      print('LoginAlertService: Security alert sent successfully');
    } catch (e) {
      print('LoginAlertService: Error sending security alert: $e');
    }
  }
  
  /// Build welcome email data
  static Future<Map<String, dynamic>> _buildWelcomeEmailData(UserModel user) async {
    final deviceInfo = await _getDeviceInfo();
    final locationInfo = await _getLocationInfo();
    
    return {
      'to': user.email,
      'subject': 'Welcome to WhispTask! 🎉',
      'html': _buildWelcomeEmailHtml(user, deviceInfo, locationInfo),
      'text': _buildWelcomeEmailText(user, deviceInfo, locationInfo),
    };
  }
  
  /// Build login alert email data
  static Future<Map<String, dynamic>> _buildLoginAlertEmailData(UserModel user) async {
    final deviceInfo = await _getDeviceInfo();
    final locationInfo = await _getLocationInfo();
    final timestamp = DateTime.now();
    
    return {
      'to': user.email,
      'subject': 'New Login to Your WhispTask Account 🔐',
      'html': _buildLoginAlertEmailHtml(user, deviceInfo, locationInfo, timestamp),
      'text': _buildLoginAlertEmailText(user, deviceInfo, locationInfo, timestamp),
    };
  }
  
  /// Build password change alert data
  static Future<Map<String, dynamic>> _buildPasswordChangeAlertData(UserModel user) async {
    final deviceInfo = await _getDeviceInfo();
    final locationInfo = await _getLocationInfo();
    final timestamp = DateTime.now();
    
    return {
      'to': user.email,
      'subject': 'Password Changed for Your WhispTask Account 🔒',
      'html': _buildPasswordChangeEmailHtml(user, deviceInfo, locationInfo, timestamp),
      'text': _buildPasswordChangeEmailText(user, deviceInfo, locationInfo, timestamp),
    };
  }
  
  /// Build security alert data
  static Future<Map<String, dynamic>> _buildSecurityAlertData(UserModel user, String alertType, String details) async {
    final deviceInfo = await _getDeviceInfo();
    final locationInfo = await _getLocationInfo();
    final timestamp = DateTime.now();
    
    return {
      'to': user.email,
      'subject': 'Security Alert for Your WhispTask Account ⚠️',
      'html': _buildSecurityAlertEmailHtml(user, alertType, details, deviceInfo, locationInfo, timestamp),
      'text': _buildSecurityAlertEmailText(user, alertType, details, deviceInfo, locationInfo, timestamp),
    };
  }
  
  /// Get device information
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'device': '${androidInfo.manufacturer} ${androidInfo.model}',
          'version': androidInfo.version.release,
          'app_version': 'WhispTask Mobile',
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'device': '${iosInfo.name} (${iosInfo.model})',
          'version': 'iOS ${iosInfo.systemVersion}',
          'app_version': 'WhispTask Mobile',
        };
      } else {
        return {
          'platform': 'Web',
          'device': 'Web Browser',
          'version': 'Web Application',
          'app_version': 'WhispTask Web',
        };
      }
    } catch (e) {
      print('LoginAlertService: Error getting device info: $e');
      return {
        'platform': 'Unknown',
        'device': 'Unknown Device',
        'version': 'Unknown',
        'app_version': 'WhispTask',
      };
    }
  }
  
  /// Get location information (approximate)
  static Future<Map<String, dynamic>> _getLocationInfo() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {'location': 'Location services disabled'};
      }
      
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {'location': 'Location permission denied'};
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return {'location': 'Location permission permanently denied'};
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
      
      // Get approximate location (city level for privacy)
      final locationName = await _getLocationName(position.latitude, position.longitude);
      
      return {
        'location': locationName,
        'approximate_coordinates': '${position.latitude.toStringAsFixed(1)}, ${position.longitude.toStringAsFixed(1)}',
      };
    } catch (e) {
      print('LoginAlertService: Error getting location: $e');
      return {'location': 'Location unavailable'};
    }
  }
  
  /// Get location name from coordinates (simplified)
  static Future<String> _getLocationName(double latitude, double longitude) async {
    try {
      // This is a simplified approach. In production, you'd use a geocoding service
      // For now, just return approximate coordinates
      return 'Approximate location: ${latitude.toStringAsFixed(1)}, ${longitude.toStringAsFixed(1)}';
    } catch (e) {
      return 'Location unavailable';
    }
  }
  
  /// Build welcome email HTML
  static String _buildWelcomeEmailHtml(UserModel user, Map<String, dynamic> deviceInfo, Map<String, dynamic> locationInfo) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Welcome to WhispTask</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: white; padding: 30px; border-radius: 0 0 10px 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
            .welcome-message { font-size: 18px; margin-bottom: 20px; }
            .features { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
            .feature-item { margin: 10px 0; padding-left: 20px; }
            .device-info { background: #e3f2fd; padding: 15px; border-radius: 8px; margin: 20px 0; font-size: 14px; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            .button { display: inline-block; background: #667eea; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin: 10px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🎉 Welcome to WhispTask!</h1>
                <p>Your voice-powered task management journey begins now</p>
            </div>
            <div class="content">
                <div class="welcome-message">
                    <p>Hi ${user.displayName},</p>
                    <p>Welcome to WhispTask! We're excited to have you on board. Your account has been successfully created and you're ready to start managing your tasks with the power of voice commands.</p>
                </div>
                
                <div class="features">
                    <h3>🚀 What you can do with WhispTask:</h3>
                    <div class="feature-item">📝 Create tasks using voice commands</div>
                    <div class="feature-item">⏰ Set smart reminders and notifications</div>
                    <div class="feature-item">🔄 Sync across all your devices</div>
                    <div class="feature-item">🎯 Track your productivity and progress</div>
                    <div class="feature-item">🔐 Secure your data with biometric authentication</div>
                </div>
                
                <div class="device-info">
                    <h4>📱 Account created from:</h4>
                    <p><strong>Device:</strong> ${deviceInfo['device']}</p>
                    <p><strong>Platform:</strong> ${deviceInfo['platform']} ${deviceInfo['version']}</p>
                    <p><strong>Location:</strong> ${locationInfo['location']}</p>
                    <p><strong>Time:</strong> ${DateTime.now().toString()}</p>
                </div>
                
                <p>If you didn't create this account, please contact our support team immediately.</p>
                
                <div style="text-align: center;">
                    <a href="mailto:support@whisptask.com" class="button">Contact Support</a>
                </div>
            </div>
            <div class="footer">
                <p>This email was sent to ${user.email}</p>
                <p>WhispTask - Voice-Powered Task Management</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }
  
  /// Build welcome email text
  static String _buildWelcomeEmailText(UserModel user, Map<String, dynamic> deviceInfo, Map<String, dynamic> locationInfo) {
    return '''
Welcome to WhispTask!

Hi ${user.displayName},

Welcome to WhispTask! We're excited to have you on board. Your account has been successfully created and you're ready to start managing your tasks with the power of voice commands.

What you can do with WhispTask:
- Create tasks using voice commands
- Set smart reminders and notifications
- Sync across all your devices
- Track your productivity and progress
- Secure your data with biometric authentication

Account created from:
Device: ${deviceInfo['device']}
Platform: ${deviceInfo['platform']} ${deviceInfo['version']}
Location: ${locationInfo['location']}
Time: ${DateTime.now().toString()}

If you didn't create this account, please contact our support team immediately at support@whisptask.com.

Best regards,
The WhispTask Team
    ''';
  }
  
  /// Build login alert email HTML
  static String _buildLoginAlertEmailHtml(UserModel user, Map<String, dynamic> deviceInfo, Map<String, dynamic> locationInfo, DateTime timestamp) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>New Login Alert - WhispTask</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: white; padding: 30px; border-radius: 0 0 10px 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
            .alert-info { background: #e8f5e8; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #4CAF50; }
            .device-info { background: #f0f8ff; padding: 15px; border-radius: 8px; margin: 20px 0; }
            .security-note { background: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ffc107; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            .button { display: inline-block; background: #dc3545; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin: 10px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🔐 New Login Detected</h1>
                <p>Your WhispTask account was accessed</p>
            </div>
            <div class="content">
                <div class="alert-info">
                    <h3>✅ Successful Login</h3>
                    <p>Hi ${user.displayName},</p>
                    <p>We detected a new login to your WhispTask account. If this was you, no action is needed.</p>
                </div>
                
                <div class="device-info">
                    <h4>📱 Login Details:</h4>
                    <p><strong>Time:</strong> ${timestamp.toString()}</p>
                    <p><strong>Device:</strong> ${deviceInfo['device']}</p>
                    <p><strong>Platform:</strong> ${deviceInfo['platform']} ${deviceInfo['version']}</p>
                    <p><strong>App:</strong> ${deviceInfo['app_version']}</p>
                    <p><strong>Location:</strong> ${locationInfo['location']}</p>
                </div>
                
                <div class="security-note">
                    <h4>🛡️ Security Notice</h4>
                    <p>If you didn't sign in to your account, your account may have been compromised. Please:</p>
                    <ul>
                        <li>Change your password immediately</li>
                        <li>Enable two-factor authentication</li>
                        <li>Review your recent account activity</li>
                        <li>Contact our support team</li>
                    </ul>
                </div>
                
                <div style="text-align: center;">
                    <a href="mailto:support@whisptask.com" class="button">Report Unauthorized Access</a>
                </div>
            </div>
            <div class="footer">
                <p>This email was sent to ${user.email}</p>
                <p>WhispTask Security Team</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }
  
  /// Build login alert email text
  static String _buildLoginAlertEmailText(UserModel user, Map<String, dynamic> deviceInfo, Map<String, dynamic> locationInfo, DateTime timestamp) {
    return '''
New Login Detected - WhispTask

Hi ${user.displayName},

We detected a new login to your WhispTask account. If this was you, no action is needed.

Login Details:
Time: ${timestamp.toString()}
Device: ${deviceInfo['device']}
Platform: ${deviceInfo['platform']} ${deviceInfo['version']}
App: ${deviceInfo['app_version']}
Location: ${locationInfo['location']}

Security Notice:
If you didn't sign in to your account, your account may have been compromised. Please:
- Change your password immediately
- Enable two-factor authentication
- Review your recent account activity
- Contact our support team at support@whisptask.com

Best regards,
WhispTask Security Team
    ''';
  }
  
  /// Build password change email HTML
  static String _buildPasswordChangeEmailHtml(UserModel user, Map<String, dynamic> deviceInfo, Map<String, dynamic> locationInfo, DateTime timestamp) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Password Changed - WhispTask</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: white; padding: 30px; border-radius: 0 0 10px 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
            .alert-info { background: #ffe6e6; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ff6b6b; }
            .device-info { background: #f0f8ff; padding: 15px; border-radius: 8px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            .button { display: inline-block; background: #dc3545; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin: 10px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🔒 Password Changed</h1>
                <p>Your WhispTask account password has been updated</p>
            </div>
            <div class="content">
                <div class="alert-info">
                    <h3>✅ Password Successfully Changed</h3>
                    <p>Hi ${user.displayName},</p>
                    <p>Your WhispTask account password has been successfully changed. If you made this change, no further action is required.</p>
                </div>
                
                <div class="device-info">
                    <h4>📱 Change Details:</h4>
                    <p><strong>Time:</strong> ${timestamp.toString()}</p>
                    <p><strong>Device:</strong> ${deviceInfo['device']}</p>
                    <p><strong>Platform:</strong> ${deviceInfo['platform']} ${deviceInfo['version']}</p>
                    <p><strong>Location:</strong> ${locationInfo['location']}</p>
                </div>
                
                <p><strong>If you didn't change your password:</strong></p>
                <ul>
                    <li>Someone else may have access to your account</li>
                    <li>Contact our support team immediately</li>
                    <li>Consider enabling additional security measures</li>
                </ul>
                
                <div style="text-align: center;">
                    <a href="mailto:support@whisptask.com" class="button">Contact Support</a>
                </div>
            </div>
            <div class="footer">
                <p>This email was sent to ${user.email}</p>
                <p>WhispTask Security Team</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }
  
  /// Build password change email text
  static String _buildPasswordChangeEmailText(UserModel user, Map<String, dynamic> deviceInfo, Map<String, dynamic> locationInfo, DateTime timestamp) {
    return '''
Password Changed - WhispTask

Hi ${user.displayName},

Your WhispTask account password has been successfully changed. If you made this change, no further action is required.

Change Details:
Time: ${timestamp.toString()}
Device: ${deviceInfo['device']}
Platform: ${deviceInfo['platform']} ${deviceInfo['version']}
Location: ${locationInfo['location']}

If you didn't change your password:
- Someone else may have access to your account
- Contact our support team immediately at support@whisptask.com
- Consider enabling additional security measures

Best regards,
WhispTask Security Team
    ''';
  }
  
  /// Build security alert email HTML
  static String _buildSecurityAlertEmailHtml(UserModel user, String alertType, String details, Map<String, dynamic> deviceInfo, Map<String, dynamic> locationInfo, DateTime timestamp) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Security Alert - WhispTask</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: linear-gradient(135deg, #dc3545 0%, #c82333 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
            .content { background: white; padding: 30px; border-radius: 0 0 10px 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
            .alert-info { background: #f8d7da; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #dc3545; }
            .device-info { background: #f0f8ff; padding: 15px; border-radius: 8px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
            .button { display: inline-block; background: #dc3545; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin: 10px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>⚠️ Security Alert</h1>
                <p>Suspicious activity detected on your WhispTask account</p>
            </div>
            <div class="content">
                <div class="alert-info">
                    <h3>🚨 Security Alert: $alertType</h3>
                    <p>Hi ${user.displayName},</p>
                    <p>We detected suspicious activity on your WhispTask account that requires your immediate attention.</p>
                    <p><strong>Details:</strong> $details</p>
                </div>
                
                <div class="device-info">
                    <h4>📱 Activity Details:</h4>
                    <p><strong>Time:</strong> ${timestamp.toString()}</p>
                    <p><strong>Device:</strong> ${deviceInfo['device']}</p>
                    <p><strong>Platform:</strong> ${deviceInfo['platform']} ${deviceInfo['version']}</p>
                    <p><strong>Location:</strong> ${locationInfo['location']}</p>
                </div>
                
                <p><strong>Recommended Actions:</strong></p>
                <ul>
                    <li>Change your password immediately</li>
                    <li>Enable two-factor authentication</li>
                    <li>Review your recent account activity</li>
                    <li>Check for any unauthorized changes</li>
                    <li>Contact our support team if needed</li>
                </ul>
                
                <div style="text-align: center;">
                    <a href="mailto:support@whisptask.com" class="button">Contact Support Immediately</a>
                </div>
            </div>
            <div class="footer">
                <p>This email was sent to ${user.email}</p>
                <p>WhispTask Security Team</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }
  
  /// Build security alert email text
  static String _buildSecurityAlertEmailText(UserModel user, String alertType, String details, Map<String, dynamic> deviceInfo, Map<String, dynamic> locationInfo, DateTime timestamp) {
    return '''
Security Alert - WhispTask

Hi ${user.displayName},

We detected suspicious activity on your WhispTask account that requires your immediate attention.

Security Alert: $alertType
Details: $details

Activity Details:
Time: ${timestamp.toString()}
Device: ${deviceInfo['device']}
Platform: ${deviceInfo['platform']} ${deviceInfo['version']}
Location: ${locationInfo['location']}

Recommended Actions:
- Change your password immediately
- Enable two-factor authentication
- Review your recent account activity
- Check for any unauthorized changes
- Contact our support team at support@whisptask.com if needed

Best regards,
WhispTask Security Team
    ''';
  }
  
  /// Send email via email service
  static Future<void> _sendEmail(Map<String, dynamic> emailData) async {
    try {
      // Send via email service API (replace with your actual service)
      final response = await http.post(
        Uri.parse(_emailServiceEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_emailApiKey',
        },
        body: jsonEncode(emailData),
      );
      
      if (response.statusCode == 200) {
        print('LoginAlertService: Email sent successfully');
      } else {
        print('LoginAlertService: Failed to send email: ${response.statusCode}');
        // Fallback: Log email content for manual sending
        _logEmailForManualSending(emailData);
      }
    } catch (e) {
      print('LoginAlertService: Error sending email: $e');
      // Fallback: Log email content for manual sending
      _logEmailForManualSending(emailData);
    }
  }
  
  /// Log email content for manual sending (fallback)
  static void _logEmailForManualSending(Map<String, dynamic> emailData) {
    print('=== EMAIL TO BE SENT MANUALLY ===');
    print('To: ${emailData['to']}');
    print('Subject: ${emailData['subject']}');
    print('Content:');
    print(emailData['text'] ?? emailData['html']);
    print('=== END EMAIL ===');
  }
  
  /// Dispose login alert service
  static void dispose() {
    _authProvider?.removeListener(_onAuthStateChanged);
  }
}
