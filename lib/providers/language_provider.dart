// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  String _currentLanguage = 'en';
  bool _isInitialized = false;

  Locale get currentLocale => _currentLocale;
  String get currentLanguage => _currentLanguage;
  bool get isInitialized => _isInitialized;

  /// Initialize the language provider
  Future<void> initialize() async {
    try {
      _currentLanguage = await LanguageService.getCurrentLanguage();
      _currentLocale = await LanguageService.getCurrentLocale();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // Fallback to default
      _currentLanguage = 'en';
      _currentLocale = const Locale('en');
      _isInitialized = true;
      notifyListeners();
    }
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

  /// Get localized text helper
  String getText(BuildContext context, String key) {
    try {
      final localizations = AppLocalizations.of(context);
      // Use reflection or a map to get the localized text
      // For now, return the key as fallback
      return key;
    } catch (e) {
      return key;
    }
  }

  /// Get available languages
  Map<String, String> get availableLanguages => LanguageService.supportedLanguages;

  /// Get current language name
  String get currentLanguageName => LanguageService.getLanguageName(_currentLanguage);
}
