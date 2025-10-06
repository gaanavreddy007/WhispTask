// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/loading_splash_overlay.dart';
import '../services/sentry_service.dart';
import '../l10n/app_localizations.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Request microphone permission with splash screen
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    final result = await SentryService.wrapWithComprehensiveTracking(
      () async {
        SentryService.logPermissionRequest('microphone', 'request_start');
        
        // Show splash screen during permission request
        String message;
        try {
          message = AppLocalizations.of(context).requestingMicrophonePermission;
          SentryService.logPermissionRequest('microphone', 'localization_loaded');
        } catch (e) {
          message = 'Requesting microphone permission...';
          SentryService.logPermissionRequest('microphone', 'localization_fallback', data: {
            'error': e.toString(),
          });
        }
        
        SplashOverlay.show(
          context,
          message: message,
          showMessage: true,
        );
        SentryService.logPermissionRequest('microphone', 'splash_overlay_shown');

        final status = await Permission.microphone.request();
        SentryService.logPermissionRequest('microphone', 'permission_requested', data: {
          'status': status.toString(),
        });
        
        // Hide splash screen
        SplashOverlay.hide();
        SentryService.logPermissionRequest('microphone', 'splash_overlay_hidden');
        
        if (status == PermissionStatus.granted) {
          SentryService.logPermissionRequest('microphone', 'granted');
          return true;
        } else if (status == PermissionStatus.permanentlyDenied) {
          SentryService.logPermissionRequest('microphone', 'permanently_denied');
          _showPermissionDialog(
            context,
            'Microphone Permission Required',
            'This app needs microphone access to function properly.',
          );
          return false;
        } else {
          SentryService.logPermissionRequest('microphone', 'denied', data: {
            'status': status.toString(),
          });
          _showPermissionDeniedDialog(
            context,
            'Microphone Permission Denied',
            'Microphone access was denied. Some features may not work.',
          );
          return false;
        }
      },
      operationName: 'request_microphone_permission',
      description: 'Request microphone permission with UI feedback',
      category: 'permission',
    ).catchError((e) {
      SentryService.logPermissionRequest('microphone', 'error', data: {
        'error': e.toString(),
      });
      SplashOverlay.hide();
      _showErrorDialog(context, 'Error requesting microphone permission: $e');
      return false;
    });
    
    return result ?? false;
  }

  // Request notification permission with splash screen
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    try {
      String message;
      try {
        message = AppLocalizations.of(context).requestingNotificationPermission;
      } catch (e) {
        message = 'Requesting notification permission...';
      }
      
      SplashOverlay.show(
        context,
        message: message,
        showMessage: true,
      );

      final status = await Permission.notification.request();
      
      SplashOverlay.hide();
      
      if (status == PermissionStatus.granted) {
        return true;
      } else if (status == PermissionStatus.permanentlyDenied) {
        _showPermissionDialog(
          context,
          'Notification Permission Required',
          'This app needs notification access to send reminders.',
        );
        return false;
      }
      return status == PermissionStatus.granted;
    } catch (e) {
      SplashOverlay.hide();
      _showErrorDialog(context, 'Error requesting notification permission: $e');
      return false;
    }
  }

  // Request storage permission with splash screen
  static Future<bool> requestStoragePermission(BuildContext context) async {
    SplashOverlay.show(
      context,
      message: AppLocalizations.of(context).requestingStoragePermission,
      showMessage: true,
    );

    try {
      final status = await Permission.storage.request();
      
      SplashOverlay.hide();
      
      if (status == PermissionStatus.granted) {
        return true;
      } else if (status == PermissionStatus.permanentlyDenied) {
        _showPermissionDialog(
          context,
          AppLocalizations.of(context).storagePermissionRequired,
          AppLocalizations.of(context).storagePermissionDescription,
        );
        return false;
      }
      return status == PermissionStatus.granted;
    } catch (e) {
      SplashOverlay.hide();
      _showErrorDialog(context, 'Error requesting storage permission: $e');
      return false;
    }
  }

  // Request camera permission with splash screen
  static Future<bool> requestCameraPermission(BuildContext context) async {
    SplashOverlay.show(
      context,
      message: AppLocalizations.of(context).requestingCameraPermission,
      showMessage: true,
    );

    try {
      final status = await Permission.camera.request();
      
      SplashOverlay.hide();
      
      if (status == PermissionStatus.granted) {
        return true;
      } else if (status == PermissionStatus.permanentlyDenied) {
        _showPermissionDialog(
          context,
          AppLocalizations.of(context).cameraPermissionRequired,
          AppLocalizations.of(context).cameraPermissionDescription,
        );
        return false;
      }
      return status == PermissionStatus.granted;
    } catch (e) {
      SplashOverlay.hide();
      _showErrorDialog(context, 'Error requesting camera permission: $e');
      return false;
    }
  }

  // Request all essential permissions with splash screen
  static Future<Map<Permission, bool>> requestEssentialPermissions(BuildContext context) async {
    SplashOverlay.show(
      context,
      message: AppLocalizations.of(context).requestingPermissions,
      showMessage: true,
    );

    try {
      final permissions = [
        Permission.microphone,
        Permission.notification,
      ];

      final statuses = await permissions.request();
      
      SplashOverlay.hide();
      
      final results = <Permission, bool>{};
      for (final permission in permissions) {
        results[permission] = statuses[permission] == PermissionStatus.granted;
      }
      
      return results;
    } catch (e) {
      SplashOverlay.hide();
      _showErrorDialog(context, 'Error requesting permissions: $e');
      return {};
    }
  }

  // Check if permission is granted
  static Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status == PermissionStatus.granted;
  }

  // Check microphone permission
  static Future<bool> isMicrophoneGranted() async {
    return await isPermissionGranted(Permission.microphone);
  }

  // Check notification permission
  static Future<bool> isNotificationGranted() async {
    return await isPermissionGranted(Permission.notification);
  }

  // Show permission dialog for permanently denied permissions
  static void _showPermissionDialog(BuildContext context, String title, String message) {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(_getSafeLocalizedText(dialogContext, 'cancel', 'Cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  openAppSettings();
                },
                child: Text(_getSafeLocalizedText(dialogContext, 'openSettings', 'Open Settings')),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error showing permission dialog: $e');
    }
  }

  // Show permission denied dialog
  static void _showPermissionDeniedDialog(BuildContext context, String title, String message) {
    try {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(_getSafeLocalizedText(dialogContext, 'ok', 'OK')),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error showing permission denied dialog: $e');
    }
  }

  // Show error dialog
  static void _showErrorDialog(BuildContext context, String message) {
    try {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(_getSafeLocalizedText(dialogContext, 'error', 'Error')),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(_getSafeLocalizedText(dialogContext, 'ok', 'OK')),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error showing error dialog: $e');
    }
  }

  // Safe localization helper
  static String _getSafeLocalizedText(BuildContext context, String key, String fallback) {
    try {
      switch (key) {
        case 'cancel':
          return AppLocalizations.of(context).cancel;
        case 'openSettings':
          return AppLocalizations.of(context).openSettings;
        case 'ok':
          return AppLocalizations.of(context).ok;
        case 'error':
          return AppLocalizations.of(context).error;
        default:
          return fallback;
      }
    } catch (e) {
      return fallback;
    }
  }
}
