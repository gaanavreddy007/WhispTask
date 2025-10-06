// Safe context access helper to prevent widget tree assertion errors
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class SafeContextHelper {
  /// Safely get localized text with fallback
  static String getLocalizedText(
    BuildContext context,
    String Function(AppLocalizations) getter,
    String fallback,
  ) {
    try {
      final localizations = AppLocalizations.of(context);
      return getter(localizations);
    } catch (e) {
      return fallback;
    }
  }

  /// Safely show dialog with context validation
  static Future<T?> showSafeDialog<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool barrierDismissible = true,
  }) async {
    try {
      if (!isContextValid(context)) return null;
      
      return await showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (dialogContext) {
          try {
            return builder(dialogContext);
          } catch (e) {
            print('Error building dialog: $e');
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade400, Colors.orange.shade600],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Oops!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Something unexpected happened while loading this dialog. Please try again.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              actions: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => safePop(dialogContext),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      );
    } catch (e) {
      print('Error showing dialog: $e');
      return null;
    }
  }

  /// Safely navigate with context validation
  static Future<T?> safePush<T extends Object?>(
    BuildContext context,
    Route<T> route,
  ) async {
    try {
      if (!context.mounted) return null;
      
      return await Navigator.of(context).push(route);
    } catch (e) {
      print('Error navigating: $e');
      return null;
    }
  }

  /// Safely navigate by name with context validation
  static Future<T?> safePushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    try {
      if (!context.mounted) return null;
      
      return await Navigator.of(context).pushNamed<T>(
        routeName,
        arguments: arguments,
      );
    } catch (e) {
      print('Error navigating to $routeName: $e');
      return null;
    }
  }

  /// Safely pop with context validation
  static void safePop<T extends Object?>(
    BuildContext context, [
    T? result,
  ]) {
    try {
      if (!context.mounted) return;
      
      Navigator.of(context).pop<T>(result);
    } catch (e) {
      print('Error popping: $e');
    }
  }

  /// Safely show snackbar with context validation
  static void showSafeSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
  }) {
    try {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: textColor ?? Colors.white),
          ),
          duration: duration,
          backgroundColor: backgroundColor,
        ),
      );
    } catch (e) {
      print('Error showing snackbar: $e');
    }
  }

  /// Safely access theme with fallback
  static ThemeData getSafeTheme(BuildContext context) {
    try {
      return Theme.of(context);
    } catch (e) {
      return ThemeData.light(); // Fallback theme
    }
  }

  /// Safely access media query with fallback
  static MediaQueryData getSafeMediaQuery(BuildContext context) {
    try {
      return MediaQuery.of(context);
    } catch (e) {
      return const MediaQueryData(); // Fallback media query
    }
  }

  /// Check if context is still valid and mounted
  static bool isContextValid(BuildContext context) {
    try {
      return context.mounted;
    } catch (e) {
      return false;
    }
  }

  /// Safely execute a function with context validation
  static T? safeExecute<T>(
    BuildContext context,
    T Function() function, {
    T? fallback,
  }) {
    try {
      if (!isContextValid(context)) return fallback;
      return function();
    } catch (e) {
      print('Error executing function: $e');
      return fallback;
    }
  }

  /// Common localized text getters with fallbacks
  static String getLoading(BuildContext context) =>
      getLocalizedText(context, (l) => l.loading, 'Loading...');

  static String getError(BuildContext context) =>
      getLocalizedText(context, (l) => l.error, 'Error');

  static String getCancel(BuildContext context) =>
      getLocalizedText(context, (l) => l.cancel, 'Cancel');

  static String getOk(BuildContext context) =>
      getLocalizedText(context, (l) => l.ok, 'OK');

  static String getRetry(BuildContext context) =>
      getLocalizedText(context, (l) => l.retry, 'Retry');

  static String getSave(BuildContext context) =>
      getLocalizedText(context, (l) => l.saveChanges, 'Save');

  /// Safely show modal bottom sheet with context validation
  static Future<T?> showSafeModalBottomSheet<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool isScrollControlled = false,
  }) async {
    try {
      if (!isContextValid(context)) return null;
      
      return await showModalBottomSheet<T>(
        context: context,
        isScrollControlled: isScrollControlled,
        builder: (sheetContext) {
          try {
            return builder(sheetContext);
          } catch (e) {
            print('Error building bottom sheet: $e');
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Error loading content'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => safePop(sheetContext),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          }
        },
      );
    } catch (e) {
      print('Error showing bottom sheet: $e');
      return null;
    }
  }

  /// Safely replace current route with context validation
  static Future<T?> safeReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Route<T> newRoute, {
    TO? result,
  }) async {
    try {
      if (!isContextValid(context)) return null;
      
      return await Navigator.of(context).pushReplacement<T, TO>(newRoute, result: result);
    } catch (e) {
      print('Error replacing route: $e');
      return null;
    }
  }

  /// Safely pop until predicate with context validation
  static void safePopUntil(
    BuildContext context,
    bool Function(Route<dynamic>) predicate,
  ) {
    try {
      if (!isContextValid(context)) return;
      
      Navigator.of(context).popUntil(predicate);
    } catch (e) {
      print('Error popping until: $e');
    }
  }

  /// Safely push and remove until with context validation
  static Future<T?> safePushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    Route<T> newRoute,
    bool Function(Route<dynamic>) predicate,
  ) async {
    try {
      if (!isContextValid(context)) return null;
      
      return await Navigator.of(context).pushAndRemoveUntil<T>(newRoute, predicate);
    } catch (e) {
      print('Error push and remove until: $e');
      return null;
    }
  }

  /// Ultimate safety wrapper for any widget operation
  static Widget safeWidget(Widget Function() builder, {Widget? fallback}) {
    try {
      return builder();
    } catch (e) {
      print('Error building widget: $e');
      return fallback ?? Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'Error loading content',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  /// Safe scaffold messenger access
  static void showSafeScaffoldMessage(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
  }) {
    try {
      if (!isContextValid(context)) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          backgroundColor: backgroundColor,
        ),
      );
    } catch (e) {
      print('Error showing scaffold message: $e');
    }
  }
}
