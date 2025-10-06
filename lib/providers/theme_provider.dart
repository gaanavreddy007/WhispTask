// ignore_for_file: prefer_const_constructors, avoid_print, deprecated_member_use, deprecated_member_use, deprecated_member_use, duplicate_ignore, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sentry_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  Future<void> initialize() async {
    if (_isInitialized) {
      SentryService.logProviderStateChange('ThemeProvider', 'initialize_skipped_already_initialized');
      return;
    }
    
    await SentryService.wrapWithComprehensiveTracking(
      () async {
        SentryService.logProviderStateChange('ThemeProvider', 'initialization_start');
        
        final prefs = await SharedPreferences.getInstance();
        final savedTheme = prefs.getString(_themeKey);
        
        SentryService.logProviderStateChange('ThemeProvider', 'preferences_loaded', data: {
          'saved_theme': savedTheme ?? 'null',
        });
        
        switch (savedTheme) {
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          default:
            _themeMode = ThemeMode.system;
        }
        
        SentryService.logProviderStateChange('ThemeProvider', 'theme_mode_set', data: {
          'theme_mode': _themeMode.toString(),
        });
        
        _isInitialized = true;
        notifyListeners();
        
        SentryService.logProviderStateChange('ThemeProvider', 'initialization_complete');
      },
      operationName: 'theme_provider_initialize',
      description: 'Initialize ThemeProvider with saved preferences',
      category: 'provider',
    ).catchError((e) {
      SentryService.logProviderStateChange('ThemeProvider', 'initialization_failed', data: {
        'error': e.toString(),
      });
      print('Failed to load theme preference: $e');
      _themeMode = ThemeMode.system;
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      SentryService.logProviderStateChange('ThemeProvider', 'set_theme_mode_skipped_same_mode', data: {
        'current_mode': _themeMode.toString(),
      });
      return;
    }
    
    await SentryService.wrapWithComprehensiveTracking(
      () async {
        final previousMode = _themeMode;
        
        SentryService.logProviderStateChange('ThemeProvider', 'theme_mode_change_start', data: {
          'previous_mode': previousMode.toString(),
          'new_mode': mode.toString(),
        });
        
        _themeMode = mode;
        notifyListeners();
        
        final prefs = await SharedPreferences.getInstance();
        String themeString;
        switch (mode) {
          case ThemeMode.dark:
            themeString = 'dark';
            break;
          case ThemeMode.light:
            themeString = 'light';
            break;
          case ThemeMode.system:
            themeString = 'system';
            break;
        }
        
        await prefs.setString(_themeKey, themeString);
        
        SentryService.logProviderStateChange('ThemeProvider', 'theme_mode_change_complete', data: {
          'previous_mode': previousMode.toString(),
          'new_mode': mode.toString(),
          'theme_string': themeString,
        });
      },
      operationName: 'theme_provider_set_mode',
      description: 'Change theme mode and persist preference',
      category: 'provider',
    ).catchError((e) {
      SentryService.logProviderStateChange('ThemeProvider', 'theme_mode_change_failed', data: {
        'error': e.toString(),
        'attempted_mode': mode.toString(),
      });
      print('Failed to save theme preference: $e');
    });
  }

  void toggleTheme() {
    switch (_themeMode) {
      case ThemeMode.light:
        setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setThemeMode(ThemeMode.system);
        break;
      case ThemeMode.system:
        setThemeMode(ThemeMode.light);
        break;
    }
  }

  // Get theme data for light mode
  static ThemeData get lightTheme {
    const primaryColor = Color(0xFF1976D2);
    const surfaceColor = Colors.white;
    const backgroundColor = Color(0xFFF5F5F5);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
        background: backgroundColor,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: const Color(0xFF42A5F5),
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        toolbarTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: surfaceColor,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        elevation: 8,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: primaryColor,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.3);
          }
          return Colors.grey.shade300;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
      ),
      textTheme: const TextTheme(
        // Headings - Large titles
        displayLarge: TextStyle(color: Colors.black87, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
        
        // Headings - Medium titles  
        headlineLarge: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        
        // Titles - Screen titles and section headers
        titleLarge: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
        
        // Body text
        bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
        bodySmall: TextStyle(color: Colors.black45, fontSize: 12),
        
        // Labels
        labelLarge: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w500),
      ),
      // Fix date picker theme to prevent BoxDecoration assertion error
      datePickerTheme: DatePickerThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        headerBackgroundColor: primaryColor,
        headerForegroundColor: Colors.white,
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        dayStyle: const TextStyle(fontSize: 14),
        weekdayStyle: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        yearStyle: const TextStyle(fontSize: 16),
        dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          if (states.contains(MaterialState.hovered)) {
            return primaryColor.withOpacity(0.1);
          }
          return Colors.transparent;
        }),
        dayForegroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          if (states.contains(MaterialState.disabled)) {
            return Colors.grey.shade400;
          }
          return Colors.black87;
        }),
        todayBackgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return primaryColor.withOpacity(0.2);
        }),
        todayForegroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return primaryColor;
        }),
      ),
    );
  }

  // Get theme data for dark mode
  static ThemeData get darkTheme {
    const primaryColor = Color(0xFF42A5F5);
    final surfaceColor = Colors.grey[850]!;
    final backgroundColor = Colors.grey[900]!;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: surfaceColor,
        background: backgroundColor,
        primary: primaryColor,
        onPrimary: Colors.black,
        secondary: const Color(0xFF90CAF9),
        onSecondary: Colors.black,
        error: Colors.redAccent,
        onError: Colors.black,
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        toolbarTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: surfaceColor,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade400,
        elevation: 8,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: primaryColor,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.grey.shade600;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.3);
          }
          return Colors.grey.shade600;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
      ),
      textTheme: const TextTheme(
        // Headings - Large titles
        displayLarge: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        
        // Headings - Medium titles  
        headlineLarge: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        
        // Titles - Screen titles and section headers
        titleLarge: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        
        // Body text
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
        bodySmall: TextStyle(color: Colors.white60, fontSize: 12),
        
        // Labels
        labelLarge: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
      ),
      // Fix date picker theme for dark mode to prevent BoxDecoration assertion error
      datePickerTheme: DatePickerThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        headerBackgroundColor: primaryColor,
        headerForegroundColor: Colors.white,
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        dayStyle: const TextStyle(fontSize: 14),
        weekdayStyle: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade400,
          fontWeight: FontWeight.w500,
        ),
        yearStyle: const TextStyle(fontSize: 16),
        dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          if (states.contains(MaterialState.hovered)) {
            return primaryColor.withOpacity(0.2);
          }
          return Colors.transparent;
        }),
        dayForegroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.black;
          }
          if (states.contains(MaterialState.disabled)) {
            return Colors.grey.shade600;
          }
          return Colors.white;
        }),
        todayBackgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return primaryColor.withOpacity(0.3);
        }),
        todayForegroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.black;
          }
          return primaryColor;
        }),
      ),
    );
  }
}
