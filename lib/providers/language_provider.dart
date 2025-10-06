// ignore_for_file: unused_local_variable, provide_deprecation_message

import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../services/sentry_service.dart';
import '../l10n/app_localizations.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  String _currentLanguage = 'en';
  bool _isInitialized = false;

  Locale get currentLocale => _currentLocale;
  String get currentLanguage => _currentLanguage;
  bool get isInitialized => _isInitialized;

  /// Initialize the language provider with optimized startup
  Future<void> initialize() async {
    await SentryService.wrapWithComprehensiveTracking(
      () async {
        SentryService.logProviderStateChange('LanguageProvider', 'initialization_start');
        
        // Set initialized immediately with defaults for faster startup
        _isInitialized = true;
        SentryService.logProviderStateChange('LanguageProvider', 'set_initialized_with_defaults');
        notifyListeners();
        
        try {
          // Load saved language asynchronously
          _currentLanguage = await LanguageService.getCurrentLanguage();
          _currentLocale = await LanguageService.getCurrentLocale();
          
          SentryService.logProviderStateChange('LanguageProvider', 'language_loaded', data: {
            'language': _currentLanguage,
            'locale': _currentLocale.toString(),
          });
          
          notifyListeners();
        } catch (e, stackTrace) {
          SentryService.captureException(
            e,
            stackTrace: stackTrace,
            hint: 'Error loading saved language preferences',
            extra: {'provider': 'LanguageProvider'},
          );
          
          // Keep defaults if loading fails
          _currentLanguage = 'en';
          _currentLocale = const Locale('en');
          
          SentryService.logProviderStateChange('LanguageProvider', 'fallback_to_defaults', data: {
            'error': e.toString(),
          });
          notifyListeners();
        }
      },
      operationName: 'language_provider_initialize',
      description: 'Initialize LanguageProvider with saved preferences',
      category: 'provider',
    );
  }

  /// Change the app language
  Future<bool> changeLanguage(String languageCode) async {
    try {
      if (!LanguageService.isLanguageSupported(languageCode)) {
        return false;
      }

      final success = await LanguageService.setLanguage(languageCode);
      if (success) {
        _currentLanguage = languageCode;
        _currentLocale = LanguageService.supportedLocales[languageCode] ?? const Locale('en');
        
        // Force immediate UI update
        notifyListeners();
        
        // Add a small delay to ensure all widgets rebuild
        await Future.delayed(const Duration(milliseconds: 100));
        notifyListeners();
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get localized text helper (deprecated - use AppLocalizations.of(context) directly)
  @deprecated
  String getText(BuildContext context, String key) {
    // This method is deprecated and should not be used
    // Use AppLocalizations.of(context).methodName directly instead
    return key;
  }

  /// Get available languages
  Map<String, String> get availableLanguages => LanguageService.supportedLanguages;

  /// Get current language name
  String get currentLanguageName => LanguageService.getLanguageName(_currentLanguage);
}
