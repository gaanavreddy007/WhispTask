import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart';

/// Centralized Sentry service for error tracking and performance monitoring
class SentryService {
  static const String _tag = 'SentryService';

  /// Capture an exception with additional context
  static Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? hint,
    Map<String, dynamic>? extra,
    String? level = 'error',
    String? fingerprint,
    String? transaction,
  }) async {
    try {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (hint != null) scope.setTag('hint', hint);
          if (extra != null) {
            extra.forEach((key, value) {
              scope.setExtra(key, value.toString());
            });
          }
          if (level != null) scope.level = _parseLevel(level);
          if (fingerprint != null) scope.fingerprint = [fingerprint];
          if (transaction != null) scope.setTag('transaction', transaction);
        },
      );
      
      if (kDebugMode) {
        print('[$_tag] Exception captured: $exception');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[$_tag] Failed to capture exception: $e');
      }
    }
  }

  /// Capture a message with context
  static Future<void> captureMessage(
    String message, {
    String level = 'info',
    Map<String, dynamic>? extra,
    String? transaction,
  }) async {
    try {
      await Sentry.captureMessage(
        message,
        level: _parseLevel(level),
        withScope: (scope) {
          if (extra != null) {
            extra.forEach((key, value) {
              scope.setExtra(key, value.toString());
            });
          }
          if (transaction != null) scope.setTag('transaction', transaction);
        },
      );
      
      if (kDebugMode) {
        print('[$_tag] Message captured: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[$_tag] Failed to capture message: $e');
      }
    }
  }

  /// Add breadcrumb for tracking user actions
  static void addBreadcrumb({
    required String message,
    String? category,
    String level = 'info',
    Map<String, dynamic>? data,
  }) {
    try {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category,
          level: _parseLevel(level),
          data: data?.map((key, value) => MapEntry(key, value.toString())),
          timestamp: DateTime.now(),
        ),
      );
      
      if (kDebugMode) {
        print('[$_tag] Breadcrumb added: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[$_tag] Failed to add breadcrumb: $e');
      }
    }
  }

  /// Set user context for better error tracking
  static Future<void> setUserContext({
    String? id,
    String? email,
    String? username,
    Map<String, dynamic>? extra,
  }) async {
    try {
      await Sentry.configureScope((scope) {
        scope.setUser(SentryUser(
          id: id,
          email: email,
          username: username,
          data: extra?.map((key, value) => MapEntry(key, value.toString())),
        ));
      });
      
      if (kDebugMode) {
        print('[$_tag] User context set: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[$_tag] Failed to set user context: $e');
      }
    }
  }

  /// Set custom tags for filtering
  static Future<void> setTag(String key, String value) async {
    try {
      await Sentry.configureScope((scope) {
        scope.setTag(key, value);
      });
      
      if (kDebugMode) {
        print('[$_tag] Tag set: $key = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[$_tag] Failed to set tag: $e');
      }
    }
  }

  /// Set custom context data
  static Future<void> setContext(String key, Map<String, dynamic> context) async {
    try {
      await Sentry.configureScope((scope) {
        scope.setContexts(key, context.map((k, v) => MapEntry(k, v.toString())));
      });
      
      if (kDebugMode) {
        print('[$_tag] Context set: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[$_tag] Failed to set context: $e');
      }
    }
  }

  /// Start a transaction for performance monitoring
  static ISentrySpan? startTransaction(
    String name,
    String operation, {
    String? description,
    Map<String, dynamic>? data,
  }) {
    try {
      final transaction = Sentry.startTransaction(
        name,
        operation,
        description: description,
      );
      
      if (data != null) {
        data.forEach((key, value) {
          transaction.setData(key, value);
        });
      }
      
      if (kDebugMode) {
        print('[$_tag] Transaction started: $name');
      }
      
      return transaction;
    } catch (e) {
      if (kDebugMode) {
        print('[$_tag] Failed to start transaction: $e');
      }
      return null;
    }
  }

  /// Wrap a function with error tracking
  static Future<T?> wrapWithErrorTracking<T>(
    Future<T> Function() function, {
    required String operation,
    String? description,
    Map<String, dynamic>? extra,
  }) async {
    final transaction = startTransaction(operation, 'function', description: description);
    
    try {
      addBreadcrumb(
        message: 'Starting operation: $operation',
        category: 'function',
        data: extra,
      );
      
      final result = await function();
      
      // Transaction completed successfully
      addBreadcrumb(
        message: 'Operation completed: $operation',
        category: 'function',
        level: 'info',
      );
      
      return result;
    } catch (e, stackTrace) {
      // Transaction failed
      
      await captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error in $operation',
        extra: extra,
        transaction: operation,
      );
      
      addBreadcrumb(
        message: 'Operation failed: $operation - $e',
        category: 'error',
        level: 'error',
      );
      
      return null;
    } finally {
      await transaction?.finish();
    }
  }

  /// Parse string level to SentryLevel
  static SentryLevel _parseLevel(String level) {
    switch (level.toLowerCase()) {
      case 'debug':
        return SentryLevel.debug;
      case 'info':
        return SentryLevel.info;
      case 'warning':
        return SentryLevel.warning;
      case 'error':
        return SentryLevel.error;
      case 'fatal':
        return SentryLevel.fatal;
      default:
        return SentryLevel.info;
    }
  }

  /// Clear user context (useful for logout)
  static Future<void> clearUserContext() async {
    try {
      await Sentry.configureScope((scope) {
        scope.setUser(null);
      });
      
      if (kDebugMode) {
        print('[$_tag] User context cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[$_tag] Failed to clear user context: $e');
      }
    }
  }

  /// Log screen navigation for better error context
  static void logScreenNavigation(String screenName, {Map<String, dynamic>? parameters}) {
    addBreadcrumb(
      message: 'Navigated to $screenName',
      category: 'navigation',
      level: 'info',
      data: parameters,
    );
  }

  /// Log user action for better error context
  static void logUserAction(String action, {Map<String, dynamic>? data}) {
    addBreadcrumb(
      message: 'User action: $action',
      category: 'user',
      level: 'info',
      data: data,
    );
  }

  /// Log API call for better error context
  static void logApiCall(String endpoint, String method, {int? statusCode, Map<String, dynamic>? data}) {
    addBreadcrumb(
      message: '$method $endpoint',
      category: 'http',
      level: statusCode != null && statusCode >= 400 ? 'error' : 'info',
      data: {
        'method': method,
        'endpoint': endpoint,
        if (statusCode != null) 'status_code': statusCode,
        ...?data,
      },
    );
  }
}

