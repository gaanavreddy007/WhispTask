// Stub implementation of flutter_background_service for iOS builds
// This provides the same API but with no-op implementations

import 'dart:async';

// Main classes exported automatically

class FlutterBackgroundService {
  static FlutterBackgroundService? _instance;
  
  static FlutterBackgroundService get instance {
    _instance ??= FlutterBackgroundService._();
    return _instance!;
  }
  
  FlutterBackgroundService._();
  
  // Stub implementation - returns false to indicate service is not available
  Future<bool> configure({
    required IosConfiguration iosConfiguration,
    required AndroidConfiguration androidConfiguration,
  }) async {
    return false;
  }
  
  // Stub implementation - returns false
  Future<bool> startService() async {
    return false;
  }
  
  // Stub implementation - returns true (always "stopped")
  Future<bool> isRunning() async {
    return false;
  }
  
  // Stub implementation - no-op
  Future<void> invoke(String method, [Map<String, dynamic>? arg]) async {
    // No-op for iOS builds
  }
  
  // Stub implementation - returns empty stream
  Stream<Map<String, dynamic>?> on(String method) {
    return const Stream.empty();
  }
}

// Configuration classes for compatibility
class IosConfiguration {
  final Function(ServiceInstance)? onForeground;
  final Function(ServiceInstance)? onBackground;
  final bool autoStart;
  
  const IosConfiguration({
    this.onForeground,
    this.onBackground,
    this.autoStart = true,
  });
}

class AndroidConfiguration {
  final Function(ServiceInstance)? onStart;
  final bool autoStart;
  final bool autoStartOnBoot;
  final String notificationChannelId;
  final String initialNotificationTitle;
  final String initialNotificationContent;
  
  const AndroidConfiguration({
    this.onStart,
    this.autoStart = true,
    this.autoStartOnBoot = false,
    required this.notificationChannelId,
    required this.initialNotificationTitle,
    required this.initialNotificationContent,
  });
}

// Service instance stub
class ServiceInstance {
  // Stub implementation - no-op
  Future<void> invoke(String method, [Map<String, dynamic>? arg]) async {
    // No-op for iOS builds
  }
  
  // Stub implementation - no-op
  void setAsForegroundService() {
    // No-op for iOS builds
  }
  
  // Stub implementation - no-op
  void setAsBackgroundService() {
    // No-op for iOS builds
  }
  
  // Stub implementation - no-op
  void stopSelf() {
    // No-op for iOS builds
  }
}
