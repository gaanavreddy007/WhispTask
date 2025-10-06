import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centralized Sentry service for error tracking and performance monitoring
class SentryService {
  static const String _tag = 'SentryService';
  static ISentrySpan? _currentTransaction;

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

  /// Start a performance transaction
  static ISentrySpan startPerformanceTransaction(String name, String operation) {
    _currentTransaction = Sentry.startTransaction(name, operation);
    addBreadcrumb(
      message: 'Started transaction: $name',
      category: 'performance',
      level: 'info',
      data: {'operation': operation},
    );
    return _currentTransaction!;
  }

  /// Finish the current transaction
  static void finishTransaction({String? status}) {
    if (_currentTransaction != null) {
      _currentTransaction!.setData('status', status ?? 'ok');
      _currentTransaction!.finish();
      addBreadcrumb(
        message: 'Finished transaction',
        category: 'performance',
        level: 'info',
        data: {'status': status ?? 'ok'},
      );
      _currentTransaction = null;
    }
  }

  /// Log widget lifecycle events
  static void logWidgetLifecycle(String widgetName, String event, {Map<String, dynamic>? data}) {
    addBreadcrumb(
      message: '$widgetName: $event',
      category: 'widget_lifecycle',
      level: 'info',
      data: {
        'widget': widgetName,
        'event': event,
        ...?data,
      },
    );
  }

  /// Log provider state changes
  static void logProviderStateChange(String providerName, String change, {Map<String, dynamic>? data}) {
    addBreadcrumb(
      message: '$providerName: $change',
      category: 'provider_state',
      level: 'info',
      data: {
        'provider': providerName,
        'change': change,
        ...?data,
      },
    );
  }

  /// Log database operations
  static void logDatabaseOperation(String operation, String table, {Map<String, dynamic>? data}) {
    addBreadcrumb(
      message: '$operation on $table',
      category: 'database',
      level: 'info',
      data: {
        'operation': operation,
        'table': table,
        ...?data,
      },
    );
  }

  /// Log permission requests
  static void logPermissionRequest(String permission, String result, {Map<String, dynamic>? data}) {
    addBreadcrumb(
      message: 'Permission $permission: $result',
      category: 'permission',
      level: result == 'granted' ? 'info' : 'warning',
      data: {
        'permission': permission,
        'result': result,
        ...?data,
      },
    );
  }

  /// Log voice operations
  static void logVoiceOperation(String operation, {Map<String, dynamic>? data}) {
    addBreadcrumb(
      message: 'Voice: $operation',
      category: 'voice',
      level: 'info',
      data: {
        'operation': operation,
        ...?data,
      },
    );
  }

  /// Log task operations
  static void logTaskOperation(String operation, {String? taskId, Map<String, dynamic>? data}) {
    addBreadcrumb(
      message: 'Task: $operation',
      category: 'task',
      level: 'info',
      data: {
        'operation': operation,
        if (taskId != null) 'task_id': taskId,
        ...?data,
      },
    );
  }

  /// Log authentication events
  static void logAuthEvent(String event, {String? userId, Map<String, dynamic>? data}) {
    addBreadcrumb(
      message: 'Auth: $event',
      category: 'auth',
      level: 'info',
      data: {
        'event': event,
        if (userId != null) 'user_id': userId,
        ...?data,
      },
    );
  }

  /// Log premium/purchase events
  static void logPurchaseEvent(String event, {String? productId, Map<String, dynamic>? data}) {
    addBreadcrumb(
      message: 'Purchase: $event',
      category: 'purchase',
      level: 'info',
      data: {
        'event': event,
        if (productId != null) 'product_id': productId,
        ...?data,
      },
    );
  }

  /// Log notification events
  static void logNotificationEvent(String event, {Map<String, dynamic>? data}) {
    addBreadcrumb(
      message: 'Notification: $event',
      category: 'notification',
      level: 'info',
      data: {
        'event': event,
        ...?data,
      },
    );
  }

  /// Log file operations
  static void logFileOperation(String operation, String fileName, {Map<String, dynamic>? data}) {
    addBreadcrumb(
      message: 'File: $operation $fileName',
      category: 'file',
      level: 'info',
      data: {
        'operation': operation,
        'file_name': fileName,
        ...?data,
      },
    );
  }

  /// Log theme/UI changes
  static void logUIEvent(String event, {Map<String, dynamic>? data}) {
    addBreadcrumb(
      message: 'UI: $event',
      category: 'ui',
      level: 'info',
      data: {
        'event': event,
        ...?data,
      },
    );
  }

  /// Comprehensive error wrapper for any operation
  static Future<T?> wrapWithComprehensiveTracking<T>(
    Future<T> Function() operation, {
    required String operationName,
    String? description,
    Map<String, dynamic>? extra,
    String category = 'operation',
  }) async {
    final transaction = startPerformanceTransaction(operationName, category);
    
    try {
      transaction.setData('description', description ?? '');
      transaction.setData('category', category);
      
      addBreadcrumb(
        message: 'Starting: $operationName',
        category: category,
        level: 'info',
        data: {
          'description': description,
          'transaction_id': transaction.context.traceId.toString(),
          ...?extra,
        },
      );

      final result = await operation();
      
      transaction.setData('result_type', result.runtimeType.toString());
      
      addBreadcrumb(
        message: 'Completed: $operationName',
        category: category,
        level: 'info',
        data: {
          'transaction_id': transaction.context.traceId.toString(),
        },
      );

      finishTransaction(status: 'ok');
      return result;
    } catch (e, stackTrace) {
      await captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error in $operationName',
        extra: {
          'operation': operationName,
          'description': description,
          'category': category,
          ...?extra,
        },
        transaction: operationName,
      );

      finishTransaction(status: 'error');
      rethrow;
    }
  }

  /// Safe operation wrapper that doesn't rethrow
  static Future<T?> safeOperation<T>(
    Future<T> Function() operation, {
    required String operationName,
    T? fallback,
    Map<String, dynamic>? extra,
  }) async {
    try {
      return await wrapWithComprehensiveTracking(
        operation,
        operationName: operationName,
        extra: extra,
      );
    } catch (e) {
      // Error already logged by wrapWithComprehensiveTracking
      return fallback;
    }
  }
}

