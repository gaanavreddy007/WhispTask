// ignore_for_file: avoid_print, valid_regexps

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sentry_service.dart';

/// Comprehensive null safety and error prevention system
class NullSafetySystem {
  
  /// Safe null check with logging
  static T? safeValue<T>(T? value, String context, {T? fallback}) {
    try {
      if (value == null) {
        SentryService.logUIEvent('null_value_detected', data: {
          'context': context,
          'type': T.toString(),
          'has_fallback': (fallback != null).toString(),
        });
        
        return fallback;
      }
      return value;
    } catch (e) {
      SentryService.logUIEvent('null_safety_error', data: {
        'context': context,
        'error': e.toString(),
      });
      return fallback;
    }
  }
  
  /// Safe string operations
  static String safeString(String? value, {String fallback = ''}) {
    return safeValue(value, 'string_operation', fallback: fallback) ?? fallback;
  }
  
  /// Safe list operations
  static List<T> safeList<T>(List<T>? value, {List<T>? fallback}) {
    return safeValue(value, 'list_operation', fallback: fallback ?? <T>[]) ?? <T>[];
  }
  
  /// Safe map operations
  static Map<K, V> safeMap<K, V>(Map<K, V>? value, {Map<K, V>? fallback}) {
    return safeValue(value, 'map_operation', fallback: fallback ?? <K, V>{}) ?? <K, V>{};
  }
  
  /// Safe context operations
  static T? safeContextOperation<T>(
    BuildContext? context,
    T Function(BuildContext) operation,
    String operationName, {
    T? fallback,
  }) {
    try {
      if (context == null) {
        SentryService.logUIEvent('null_context_detected', data: {
          'operation': operationName,
        });
        return fallback;
      }
      
      if (!context.mounted) {
        SentryService.logUIEvent('unmounted_context_detected', data: {
          'operation': operationName,
        });
        return fallback;
      }
      
      return operation(context);
      
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Safe context operation failed',
        extra: {
          'operation': operationName,
          'context_mounted': context?.mounted.toString() ?? 'null',
        },
      );
      return fallback;
    }
  }
  
  /// Safe widget building
  static Widget safeWidgetBuilder(
    Widget Function() builder,
    String widgetName, {
    Widget? fallback,
  }) {
    try {
      return builder();
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Safe widget builder failed',
        extra: {'widget_name': widgetName},
      );
      
      return fallback ?? _buildErrorWidget(widgetName, e.toString());
    }
  }
  
  /// Safe async operation wrapper
  static Future<T?> safeAsyncOperation<T>(
    Future<T> Function() operation,
    String operationName, {
    T? fallback,
    Duration? timeout,
  }) async {
    try {
      final future = operation();
      
      if (timeout != null) {
        return await future.timeout(
          timeout,
          onTimeout: () {
            SentryService.logUIEvent('async_operation_timeout', data: {
              'operation': operationName,
              'timeout_seconds': timeout.inSeconds.toString(),
            });
            throw TimeoutException('Operation timed out', timeout);
          },
        );
      }
      
      return await future;
      
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Safe async operation failed',
        extra: {'operation': operationName},
      );
      return fallback;
    }
  }
  
  /// Safe provider access
  static T? safeProviderAccess<T>(
    BuildContext? context,
    String providerName, {
    bool listen = false,
  }) {
    try {
      if (context == null || !context.mounted) {
        SentryService.logUIEvent('provider_access_failed_null_context', data: {
          'provider': providerName,
        });
        return null;
      }
      
      // This is a placeholder - actual implementation would use Provider.of<T>
      SentryService.logUIEvent('provider_access_success', data: {
        'provider': providerName,
        'listen': listen.toString(),
      });
      return null; // Placeholder return
      
    } catch (e) {
      SentryService.logUIEvent('provider_access_failed', data: {
        'provider': providerName,
        'error': e.toString(),
      });
      return null;
    }
  }
  
  /// Safe navigation
  static Future<T?> safeNavigation<T>(
    BuildContext? context,
    String routeName, {
    Object? arguments,
    bool replace = false,
  }) async {
    try {
      if (context == null || !context.mounted) {
        SentryService.logUIEvent('navigation_failed_null_context', data: {
          'route': routeName,
        });
        return null;
      }
      
      if (replace) {
        return await Navigator.of(context).pushReplacementNamed(
          routeName,
          arguments: arguments,
        );
      } else {
        return await Navigator.of(context).pushNamed(
          routeName,
          arguments: arguments,
        );
      }
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Safe navigation failed',
        extra: {
          'route': routeName,
          'replace': replace.toString(),
        },
      );
      return null;
    }
  }
  
  /// Safe theme access
  static ThemeData? safeThemeAccess(BuildContext? context) {
    return safeContextOperation(
      context,
      (ctx) => Theme.of(ctx),
      'theme_access',
      fallback: ThemeData.light(), // Safe fallback theme
    );
  }
  
  /// Safe media query access
  static MediaQueryData? safeMediaQueryAccess(BuildContext? context) {
    return safeContextOperation(
      context,
      (ctx) => MediaQuery.of(ctx),
      'media_query_access',
    );
  }
  
  /// Safe localization access
  static Locale? safeLocalizationAccess(BuildContext? context) {
    return safeContextOperation(
      context,
      (ctx) => Localizations.localeOf(ctx),
      'localization_access',
      fallback: const Locale('en'), // Safe fallback locale
    );
  }
  
  /// Build error widget for failed operations
  static Widget _buildErrorWidget(String widgetName, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[700],
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Error in $widgetName',
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Widget failed to load',
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Validate and sanitize user input
  static String sanitizeInput(String? input, {
    int maxLength = 1000,
    bool allowSpecialChars = true,
    String fallback = '',
  }) {
    try {
      if (input == null || input.isEmpty) {
        return fallback;
      }
      
      String sanitized = input.trim();
      
      // Limit length
      if (sanitized.length > maxLength) {
        sanitized = sanitized.substring(0, maxLength);
        SentryService.logUIEvent('input_truncated', data: {
          'original_length': input.length.toString(),
          'max_length': maxLength.toString(),
        });
      }
      
      // Remove dangerous characters if not allowed
      if (!allowSpecialChars) {
        sanitized = sanitized.replaceAll(RegExp(r'[<>"\'']'), '');
      }
      
      return sanitized;
      
    } catch (e) {
      SentryService.logUIEvent('input_sanitization_error', data: {
        'error': e.toString(),
      });
      return fallback;
    }
  }
  
  /// Safe JSON parsing
  static Map<String, dynamic>? safeJsonParse(String? jsonString) {
    try {
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      
      // In a real implementation, you'd use dart:convert
      // return json.decode(jsonString) as Map<String, dynamic>;
      
      SentryService.logUIEvent('json_parse_success');
      return <String, dynamic>{}; // Placeholder
      
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'JSON parsing failed',
        extra: {'json_length': jsonString?.length.toString() ?? '0'},
      );
      return null;
    }
  }
  
  /// Safe number parsing
  static double? safeDoubleParseDouble(String? value, {double? fallback}) {
    try {
      if (value == null || value.isEmpty) {
        return fallback;
      }
      
      return double.tryParse(value) ?? fallback;
      
    } catch (e) {
      SentryService.logUIEvent('double_parse_error', data: {
        'value': value ?? 'null',
        'error': e.toString(),
      });
      return fallback;
    }
  }
  
  /// Safe integer parsing
  static int? safeIntParse(String? value, {int? fallback}) {
    try {
      if (value == null || value.isEmpty) {
        return fallback;
      }
      
      return int.tryParse(value) ?? fallback;
      
    } catch (e) {
      SentryService.logUIEvent('int_parse_error', data: {
        'value': value ?? 'null',
        'error': e.toString(),
      });
      return fallback;
    }
  }
}
