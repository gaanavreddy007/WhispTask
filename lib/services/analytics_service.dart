// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';

class AnalyticsService {
  static const String _adminEmail = 'admin@whisptask.com'; // Replace with actual admin email
  static const String _analyticsEndpoint = 'https://your-analytics-server.com/api/analytics'; // Replace with actual endpoint
  
  static bool _isEnabled = true;
  static AuthProvider? _authProvider;
  
  /// Initialize analytics service
  static void initialize(AuthProvider authProvider) {
    _authProvider = authProvider;
    _updateAnalyticsPreference();
    
    // Listen for preference changes
    authProvider.addListener(_updateAnalyticsPreference);
  }
  
  /// Update analytics preference based on user settings
  static void _updateAnalyticsPreference() {
    final user = _authProvider?.user;
    _isEnabled = user?.privacySettings?.shareAnalytics ?? true;
    print('AnalyticsService: Analytics ${_isEnabled ? "enabled" : "disabled"}');
  }
  
  /// Track app events
  static Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    if (!_isEnabled) {
      print('AnalyticsService: Analytics disabled, skipping event: $eventName');
      return;
    }
    
    try {
      final eventData = await _buildEventData(eventName, parameters);
      await _sendAnalyticsData(eventData);
      print('AnalyticsService: Event tracked: $eventName');
    } catch (e) {
      print('AnalyticsService: Error tracking event $eventName: $e');
    }
  }
  
  /// Track screen views
  static Future<void> trackScreenView(String screenName) async {
    await trackEvent('screen_view', parameters: {'screen_name': screenName});
  }
  
  /// Track user actions
  static Future<void> trackUserAction(String action, {Map<String, dynamic>? data}) async {
    await trackEvent('user_action', parameters: {'action': action, ...?data});
  }
  
  /// Track app performance
  static Future<void> trackPerformance(String metric, double value) async {
    await trackEvent('performance_metric', parameters: {'metric': metric, 'value': value});
  }
  
  /// Track feature usage
  static Future<void> trackFeatureUsage(String feature, {Map<String, dynamic>? context}) async {
    await trackEvent('feature_usage', parameters: {'feature': feature, ...?context});
  }
  
  /// Build comprehensive event data
  static Future<Map<String, dynamic>> _buildEventData(String eventName, Map<String, dynamic>? parameters) async {
    final deviceInfo = await _getDeviceInfo();
    final appInfo = await _getAppInfo();
    final user = _authProvider?.user;
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'event_name': eventName,
      'parameters': parameters ?? {},
      'user_id': user?.uid ?? 'anonymous',
      'user_email': user?.email ?? 'anonymous',
      'session_id': _generateSessionId(),
      'app_info': appInfo,
      'device_info': deviceInfo,
      'platform': defaultTargetPlatform.name,
    };
  }
  
  /// Get device information
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'version': iosInfo.systemVersion,
        };
      }
    } catch (e) {
      print('AnalyticsService: Error getting device info: $e');
    }
    
    return {'platform': 'unknown'};
  }
  
  /// Get app information
  static Future<Map<String, dynamic>> _getAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'app_name': packageInfo.appName,
        'package_name': packageInfo.packageName,
        'version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
      };
    } catch (e) {
      print('AnalyticsService: Error getting app info: $e');
      return {'app_name': 'WhispTask'};
    }
  }
  
  /// Generate session ID
  static String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  /// Send analytics data to admin
  static Future<void> _sendAnalyticsData(Map<String, dynamic> data) async {
    try {
      // Send to analytics server (replace with your actual endpoint)
      final response = await http.post(
        Uri.parse(_analyticsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_KEY', // Replace with actual API key
        },
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 200) {
        print('AnalyticsService: Data sent successfully');
      } else {
        print('AnalyticsService: Failed to send data: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback: Send via email (for demo purposes)
      await _sendAnalyticsEmail(data);
    }
  }
  
  /// Fallback: Send analytics via email
  static Future<void> _sendAnalyticsEmail(Map<String, dynamic> data) async {
    try {
      // This is a simplified email sending approach
      // In production, you'd use a proper email service like SendGrid, AWS SES, etc.
      final emailData = {
        'to': _adminEmail,
        'subject': 'WhispTask Analytics Data',
        'body': _formatAnalyticsForEmail(data),
      };
      
      // Send email via your email service
      print('AnalyticsService: Would send email to $_adminEmail with data: ${jsonEncode(emailData)}');
      
      // For now, just log the data that would be sent
      print('Analytics Data: ${jsonEncode(data)}');
    } catch (e) {
      print('AnalyticsService: Error sending analytics email: $e');
    }
  }
  
  /// Format analytics data for email
  static String _formatAnalyticsForEmail(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('WhispTask Analytics Report');
    buffer.writeln('========================');
    buffer.writeln('Timestamp: ${data['timestamp']}');
    buffer.writeln('Event: ${data['event_name']}');
    buffer.writeln('User: ${data['user_email']} (${data['user_id']})');
    buffer.writeln('');
    buffer.writeln('Parameters:');
    final parameters = data['parameters'] as Map<String, dynamic>?;
    parameters?.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });
    buffer.writeln('');
    buffer.writeln('Device Info:');
    final deviceInfo = data['device_info'] as Map<String, dynamic>?;
    deviceInfo?.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });
    buffer.writeln('');
    buffer.writeln('App Info:');
    final appInfo = data['app_info'] as Map<String, dynamic>?;
    appInfo?.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });
    
    return buffer.toString();
  }
  
  /// Dispose analytics service
  static void dispose() {
    _authProvider?.removeListener(_updateAnalyticsPreference);
  }
}

/// Common analytics events
class AnalyticsEvents {
  static const String appLaunched = 'app_launched';
  static const String userLoggedIn = 'user_logged_in';
  static const String userLoggedOut = 'user_logged_out';
  static const String taskCreated = 'task_created';
  static const String taskCompleted = 'task_completed';
  static const String taskDeleted = 'task_deleted';
  static const String voiceCommandUsed = 'voice_command_used';
  static const String biometricAuthUsed = 'biometric_auth_used';
  static const String settingsChanged = 'settings_changed';
  static const String premiumPurchased = 'premium_purchased';
  static const String errorOccurred = 'error_occurred';
}
