// ignore_for_file: avoid_print, unused_local_variable, constant_identifier_names, unused_element, unused_import, unnecessary_import

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Providers
import 'package:whisptask/providers/auth_provider.dart';
import 'package:whisptask/providers/task_provider.dart';
import 'package:whisptask/providers/theme_provider.dart';
import 'package:whisptask/providers/voice_provider.dart';
import 'package:whisptask/providers/language_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/add_task_screen.dart';
import 'screens/voice_input_screen.dart';
import 'screens/account_settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/premium_purchase_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/statistics_screen.dart';

// Widgets
import 'widgets/task_calendar.dart';

// Services
import 'services/notification_service.dart';
import 'services/tts_service.dart';
import 'services/widget_service.dart';
import 'services/web_payment_service.dart';
import 'services/ad_service.dart';
import 'services/voice_service.dart';

// Widgets
import 'widgets/auth_wrapper.dart';

// Localization
import 'l10n/app_localizations.dart';

// Initialize notification plugin globally
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://57a64cf15be0fbc47501e30720a65089@o4509944727142400.ingest.us.sentry.io/4509944729174016';
      // Reduce sample rate for better performance
      options.tracesSampleRate = kDebugMode ? 0.5 : 0.05; // Reduced for faster startup
      options.debug = false; // Disable debug for faster startup
      options.environment = kDebugMode ? 'development' : 'production';
      options.sendDefaultPii = false;
      options.enablePrintBreadcrumbs = false; // Disable for faster startup
      options.dist = '1';
      options.release = 'whisptask@1.0.0+1';
      
      // Disable detailed logging for faster startup
      // Only enable in debug mode if needed for debugging
      
      // Filter out non-critical events in production
      options.beforeSend = (event, {hint}) {
        // Skip debug/info level events in production for performance
        if (!kDebugMode && event.level != null) {
          if (event.level == SentryLevel.debug || event.level == SentryLevel.info) {
            return null; // Don't send debug/info events in production
          }
        }
        return event;
      };
    },
    appRunner: () async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handling for crashes - integrate with Sentry
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    
    // Special handling for LateInitializationError
    final errorMessage = details.exception.toString();
    if (errorMessage.contains('LateInitializationError') || errorMessage.contains('has not been initialized')) {
      print('🚨 CRITICAL: LateInitializationError detected - ${details.exception}');
      print('Stack trace: ${details.stack}');
    }
    
    // Send to Sentry
    Sentry.captureException(
      details.exception,
      stackTrace: details.stack,
    );
    
    // Log to Firebase Analytics for crash tracking
    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'flutter_error',
        parameters: {
          'error': details.exception.toString(),
          'stack': details.stack.toString().substring(0, 500), // Limit length
          'is_late_error': errorMessage.contains('LateInitializationError') ? 'true' : 'false',
        },
      );
    } catch (e) {
      print('Error logging failed: $e');
    }
  };

  // Handle platform errors (including LateInitializationError)
  PlatformDispatcher.instance.onError = (error, stack) {
    final errorMessage = error.toString();
    if (errorMessage.contains('LateInitializationError') || errorMessage.contains('has not been initialized')) {
      print('🚨 CRITICAL: Platform LateInitializationError - $error');
      print('Stack trace: $stack');
    }
    
    Sentry.captureException(error, stackTrace: stack);
    return true;
  };

  try {
    // Initialize Firebase first (required for other services)
    await Firebase.initializeApp();
    print('Firebase initialized successfully');

    // Initialize only timezone data synchronously (ultra-lightweight)
    tz.initializeTimeZones();
    print('Timezone data initialized');
    
    // Move ALL other services to background initialization
    Future.microtask(() async {
      try {
        await NotificationService().initialize();
        print('Notification service initialized');
      } catch (e) {
        print('Notification service failed: $e');
      }
    });
    
    // Initialize Firebase App Check in background (not critical for startup)
    Future.microtask(() async {
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
        );
        print('Firebase App Check initialized');
      } catch (e) {
        print('Firebase App Check initialization failed: $e');
      }
    });

    // Initialize Firebase Analytics in background (non-blocking)
    Future.microtask(() {
      FirebaseAnalytics analytics = FirebaseAnalytics.instance;
      print('Firebase Analytics initialized');
    });

    // Initialize non-critical services in background after app starts (faster delay)
    _initializeNonCriticalServices();
    
  } catch (e) {
    print('Initialization error: $e');
    // Log initialization errors
    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'initialization_error',
        parameters: {'error': e.toString()},
      );
    } catch (_) {}
  }

  runApp(const WhispTaskApp());
    },
  );
}

// Initialize non-critical services in background after app starts
void _initializeNonCriticalServices() {
  // Remove delay completely for instant background loading
  Future.microtask(() async {
    try {
      // Initialize services in parallel without waiting - fire and forget
      TtsService().initialize().then((_) => print('TTS service initialized')).catchError((e) => print('TTS init error: $e'));
      WidgetService.initializeWidget().then((_) => print('Widget service initialized')).catchError((e) => print('Widget init error: $e'));
      WebPaymentService.initialize().then((_) => print('Web Payment service initialized')).catchError((e) => print('Payment init error: $e'));
      AdService.initialize().then((_) => print('Ad service initialized')).catchError((e) => print('Ad init error: $e'));
      
      print('All non-critical services started in background');
    } catch (e) {
      print('Non-critical service initialization error: $e');
      // Log but don't block app startup
      try {
        FirebaseAnalytics.instance.logEvent(
          name: 'background_init_error',
          parameters: {'error': e.toString()},
        );
      } catch (_) {}
    }
  });
}

class WhispTaskApp extends StatelessWidget {
  const WhispTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthProvider - Critical, load immediately with optimized initialization
        ChangeNotifierProvider(
          create: (_) {
            final provider = AuthProvider();
            // Start auth initialization immediately in background
            Future.microtask(() => provider.initializeAuth());
            return provider;
          },
        ),
        
        // LanguageProvider - Critical for localization, ultra-fast initialization
        ChangeNotifierProvider(
          create: (_) {
            final provider = LanguageProvider();
            // Initialize immediately in microtask for instant startup
            Future.microtask(() => provider.initialize());
            return provider;
          },
          lazy: false,
        ),
        
        // ThemeProvider - Critical for UI, ultra-fast initialization
        ChangeNotifierProvider(
          create: (_) {
            final provider = ThemeProvider();
            // Initialize immediately in microtask for instant startup
            Future.microtask(() => provider.initialize());
            return provider;
          },
          lazy: false,
        ),
        
        // VoiceProvider - Not immediately needed, lazy load
        ChangeNotifierProvider(
          create: (_) => VoiceProvider(),
          lazy: true,
        ),
        
        // Task Provider with Auth dependency - Ultra-fast lazy loaded
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) {
            final provider = TaskProvider();
            // Pre-initialize voice commands in background
            Future.microtask(() => provider.initializeVoiceCommands());
            return provider;
          },
          update: (_, auth, previous) {
            if (previous != null) {
              previous.updateAuth(auth);
              return previous;
            } else {
              final taskProvider = TaskProvider();
              taskProvider.updateAuth(auth);
              // Pre-initialize voice commands in background
              Future.microtask(() => taskProvider.initializeVoiceCommands());
              return taskProvider;
            }
          },
          lazy: true, // Load only when first accessed
        ),
      ],
      child: Consumer3<AuthProvider, ThemeProvider, LanguageProvider>(
        builder: (context, authProvider, themeProvider, languageProvider, _) {
          return MaterialApp(
            title: 'WhispTask',
            // Optimize for faster startup
            debugShowCheckedModeBanner: false,
            showPerformanceOverlay: false,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            
            // Localization support with dynamic locale
            locale: languageProvider.currentLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            
            // Force rebuild when locale changes
            key: ValueKey('${languageProvider.currentLocale.languageCode}_${languageProvider.isInitialized}'),
            
            // Add Firebase Analytics observer
            navigatorObservers: [
              FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
            ],
            
            // Show splash screen while initializing
            home: authProvider.isInitialized 
                ? const AuthWrapper() 
                : const SplashScreen(),
            
            // Define all app routes
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/auth-wrapper': (context) => const AuthWrapper(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/home': (context) => const AuthWrapper(),
              '/add-task': (context) => const AddTaskScreen(),
              '/voice-input': (context) => const VoiceInputScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/account-settings': (context) => const AccountSettingsScreen(),
              '/change-password': (context) => const ChangePasswordScreen(),
              '/premium-purchase': (context) => const PremiumPurchaseScreen(),
              '/calendar': (context) => const TaskCalendar(),
              '/achievements': (context) => const AchievementsScreen(),
              '/habits': (context) => const HabitsScreen(),
              '/focus': (context) => const FocusScreen(),
              '/statistics': (context) => const StatisticsScreen(),
            },
            
            // Handle unknown routes
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const AuthWrapper(),
              );
            },
          );
        },
      ),
    );
  }

}