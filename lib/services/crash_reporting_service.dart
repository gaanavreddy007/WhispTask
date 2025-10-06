// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';

class CrashReportingService {
  static const String _adminEmail = 'admin@whisptask.com'; // Replace with actual admin email
  static const String _crashEndpoint = 'https://your-crash-server.com/api/crashes'; // Replace with actual endpoint
  
  static bool _isEnabled = true;
  static AuthProvider? _authProvider;
  
  /// Initialize crash reporting service
  static void initialize(AuthProvider authProvider) {
    _authProvider = authProvider;
    _updateCrashReportingPreference();
    
    // Listen for preference changes
    authProvider.addListener(_updateCrashReportingPreference);
    
    // Set up global error handling
    _setupErrorHandling();
  }
  
  /// Update crash reporting preference based on user settings
  static void _updateCrashReportingPreference() {
    final user = _authProvider?.user;
    _isEnabled = user?.privacySettings?.shareCrashReports ?? true;
    print('CrashReportingService: Crash reporting ${_isEnabled ? "enabled" : "disabled"}');
  }
  
  /// Setup global error handling
  static void _setupErrorHandling() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      reportError(
        details.exception,
        details.stack,
        context: 'Flutter Framework Error',
        additionalData: {
          'library': details.library,
          'context': details.context?.toString(),
        },
      );
    };
    
    // Handle platform errors (iOS/Android)
    PlatformDispatcher.instance.onError = (error, stack) {
      reportError(
        error,
        stack,
        context: 'Platform Error',
      );
      return true;
    };
  }
  
  /// Report an error/crash
  static Future<void> reportError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool isFatal = false,
  }) async {
    if (!_isEnabled) {
      print('CrashReportingService: Crash reporting disabled, skipping error report');
      return;
    }
    
    try {
      final crashData = await _buildCrashData(
        error,
        stackTrace,
        context: context,
        additionalData: additionalData,
        isFatal: isFatal,
      );
      
      await _sendCrashReport(crashData);
      print('CrashReportingService: Crash report sent for: ${error.toString()}');
    } catch (e) {
      print('CrashReportingService: Error sending crash report: $e');
    }
  }
  
  /// Report a non-fatal error
  static Future<void> reportNonFatalError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    await reportError(
      error,
      stackTrace,
      context: context,
      additionalData: additionalData,
      isFatal: false,
    );
  }
  
  /// Report a handled exception
  static Future<void> reportHandledException(
    dynamic exception,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    await reportError(
      exception,
      stackTrace,
      context: context ?? 'Handled Exception',
      additionalData: additionalData,
      isFatal: false,
    );
  }
  
  /// Build comprehensive crash data
  static Future<Map<String, dynamic>> _buildCrashData(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool isFatal = false,
  }) async {
    final deviceInfo = await _getDeviceInfo();
    final appInfo = await _getAppInfo();
    final systemInfo = await _getSystemInfo();
    final user = _authProvider?.user;
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'error_type': error.runtimeType.toString(),
      'error_message': error.toString(),
      'stack_trace': stackTrace?.toString() ?? 'No stack trace available',
      'context': context ?? 'Unknown',
      'is_fatal': isFatal,
      'user_id': user?.uid ?? 'anonymous',
      'user_email': user?.email ?? 'anonymous',
      'session_id': _generateSessionId(),
      'app_info': appInfo,
      'device_info': deviceInfo,
      'system_info': systemInfo,
      'additional_data': additionalData ?? {},
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
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'hardware': androidInfo.hardware,
          'is_physical_device': androidInfo.isPhysicalDevice,
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'version': iosInfo.systemVersion,
          'is_physical_device': iosInfo.isPhysicalDevice,
        };
      }
    } catch (e) {
      print('CrashReportingService: Error getting device info: $e');
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
      print('CrashReportingService: Error getting app info: $e');
      return {'app_name': 'WhispTask'};
    }
  }
  
  /// Get system information
  static Future<Map<String, dynamic>> _getSystemInfo() async {
    try {
      return {
        'dart_version': Platform.version,
        'operating_system': Platform.operatingSystem,
        'operating_system_version': Platform.operatingSystemVersion,
        'locale': Platform.localeName,
        'number_of_processors': Platform.numberOfProcessors,
      };
    } catch (e) {
      print('CrashReportingService: Error getting system info: $e');
      return {};
    }
  }
  
  /// Generate session ID
  static String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  /// Send crash report to admin
  static Future<void> _sendCrashReport(Map<String, dynamic> crashData) async {
    try {
      // Send to crash reporting server (replace with your actual endpoint)
      final response = await http.post(
        Uri.parse(_crashEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_KEY', // Replace with actual API key
        },
        body: jsonEncode(crashData),
      );
      
      if (response.statusCode == 200) {
        print('CrashReportingService: Crash report sent successfully');
      } else {
        print('CrashReportingService: Failed to send crash report: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback: Send via email (for demo purposes)
      await _sendCrashEmail(crashData);
    }
  }
  
  /// Fallback: Send crash report via email
  static Future<void> _sendCrashEmail(Map<String, dynamic> crashData) async {
    try {
      final emailData = {
        'to': _adminEmail,
        'subject': 'WhispTask Crash Report - ${crashData['is_fatal'] ? 'FATAL' : 'NON-FATAL'}',
        'body': _formatCrashForEmail(crashData),
        'priority': crashData['is_fatal'] ? 'high' : 'normal',
      };
      
      // Send email via your email service
      print('CrashReportingService: Would send crash email to ${emailData['to']} with subject: ${emailData['subject']}');
      
      // For now, just log the crash data that would be sent
      print('Crash Data: ${jsonEncode(crashData)}');
    } catch (e) {
      print('CrashReportingService: Error sending crash email: $e');
    }
  }
  
  /// Format crash data for email
  static String _formatCrashForEmail(Map<String, dynamic> crashData) {
    final buffer = StringBuffer();
    buffer.writeln('WhispTask Crash Report');
    buffer.writeln('=====================');
    buffer.writeln('Timestamp: ${crashData['timestamp']}');
    buffer.writeln('Severity: ${crashData['is_fatal'] ? 'FATAL CRASH' : 'Non-Fatal Error'}');
    buffer.writeln('User: ${crashData['user_email']} (${crashData['user_id']})');
    buffer.writeln('Context: ${crashData['context']}');
    buffer.writeln('');
    buffer.writeln('Error Details:');
    buffer.writeln('  Type: ${crashData['error_type']}');
    buffer.writeln('  Message: ${crashData['error_message']}');
    buffer.writeln('');
    buffer.writeln('Stack Trace:');
    buffer.writeln(crashData['stack_trace']);
    buffer.writeln('');
    buffer.writeln('Device Info:');
    final deviceInfo = crashData['device_info'] as Map<String, dynamic>?;
    deviceInfo?.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });
    buffer.writeln('');
    buffer.writeln('App Info:');
    final appInfo = crashData['app_info'] as Map<String, dynamic>?;
    appInfo?.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });
    buffer.writeln('');
    buffer.writeln('System Info:');
    final systemInfo = crashData['system_info'] as Map<String, dynamic>?;
    systemInfo?.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });
    
    final additionalData = crashData['additional_data'] as Map<String, dynamic>?;
    if (additionalData != null && additionalData.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Additional Data:');
      additionalData.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    
    return buffer.toString();
  }
  
  /// Dispose crash reporting service
  static void dispose() {
    _authProvider?.removeListener(_updateCrashReportingPreference);
  }
}

/// Wrapper for easy error reporting
class CrashReporter {
  /// Report and rethrow an error
  static Future<T> reportAndRethrow<T>(Future<T> Function() operation, {String? context}) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      await CrashReportingService.reportNonFatalError(
        error,
        stackTrace,
        context: context,
      );
      rethrow;
    }
  }
  
  /// Report an error without rethrowing
  static Future<T?> reportAndContinue<T>(Future<T> Function() operation, {String? context}) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      await CrashReportingService.reportNonFatalError(
        error,
        stackTrace,
        context: context,
      );
      return null;
    }
  }
}
