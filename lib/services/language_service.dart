import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';
  
  // Supported languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'hi': 'हिंदी',
    'kn': 'ಕನ್ನಡ',
  };
  
  static const Map<String, Locale> supportedLocales = {
    'en': Locale('en'),
    'hi': Locale('hi'),
    'kn': Locale('kn'),
  };

  /// Get the current selected language
  static Future<String> getCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey) ?? _defaultLanguage;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('service', 'language');
          scope.setTag('operation', 'get_current_language');
          scope.level = SentryLevel.warning;
        },
      );
      return _defaultLanguage;
    }
  }

  /// Set the selected language
  static Future<bool> setLanguage(String languageCode) async {
    try {
      if (!supportedLanguages.containsKey(languageCode)) {
        throw Exception('Unsupported language: $languageCode');
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      return true;
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('service', 'language');
          scope.setTag('operation', 'set_language');
          scope.setExtra('language_code', languageCode);
          scope.level = SentryLevel.error;
        },
      );
      return false;
    }
  }

  /// Get the current locale
  static Future<Locale> getCurrentLocale() async {
    try {
      final languageCode = await getCurrentLanguage();
      return supportedLocales[languageCode] ?? const Locale('en');
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('service', 'language');
          scope.setTag('operation', 'get_current_locale');
          scope.level = SentryLevel.warning;
        },
      );
      return const Locale('en');
    }
  }

  /// Get language name by code
  static String getLanguageName(String languageCode) {
    return supportedLanguages[languageCode] ?? 'Unknown';
  }

  /// Check if language is supported
  static bool isLanguageSupported(String languageCode) {
    return supportedLanguages.containsKey(languageCode);
  }

  /// Get system language if supported, otherwise return default
  static String getSystemLanguageOrDefault() {
    try {
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final systemLanguage = systemLocale.languageCode;
      
      if (isLanguageSupported(systemLanguage)) {
        return systemLanguage;
      }
      return _defaultLanguage;
    } catch (e) {
      return _defaultLanguage;
    }
  }

  /// Initialize language service with system language if not set
  static Future<void> initialize() async {
    try {
      final currentLanguage = await getCurrentLanguage();
      
      // If no language is set, use system language or default
      if (currentLanguage == _defaultLanguage) {
        final systemLanguage = getSystemLanguageOrDefault();
        if (systemLanguage != _defaultLanguage) {
          await setLanguage(systemLanguage);
        }
      }
    } catch (e) {
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('service', 'language');
          scope.setTag('operation', 'initialize');
          scope.level = SentryLevel.warning;
        },
      );
    }
  }
}
