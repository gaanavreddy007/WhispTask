// ignore_for_file: avoid_print, unused_local_variable, constant_identifier_names, unused_element, unused_import

import 'package:flutter/material.dart';
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

// Widgets
import 'widgets/task_calendar.dart';

// Services
import 'services/notification_service.dart';
import 'services/tts_service.dart';
import 'services/widget_service.dart';
import 'services/revenue_cat_service.dart';
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
      options.tracesSampleRate = 1.0;
      options.debug = true;
      options.environment = 'development';
      options.sendDefaultPii = false;
      options.enablePrintBreadcrumbs = true;
      // Force send in debug mode
      options.dist = '1';
      options.release = 'whisptask@1.0.0+1';
      // Enhanced logging
      options.beforeSend = (event, {hint}) {
        print('=== SENTRY DEBUG ===');
        print('Event ID: ${event.eventId}');
        print('Event Type: ${event.type}');
        print('Message: ${event.message?.formatted}');
        print('DSN: ${options.dsn}');
        print('Environment: ${event.environment}');
        print('Release: ${event.release}');
        print('==================');
        return event;
      };
    },
    appRunner: () async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handling for crashes - integrate with Sentry
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    
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
        },
      );
    } catch (e) {
      print('Error logging failed: $e');
    }
  };

  try {
    // Initialize Firebase first (required for other services)
    await Firebase.initializeApp();
    print('Firebase initialized successfully');

    // Initialize critical services in parallel
    await Future.wait([
      // Firebase App Check for security
      FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
      ).then((_) => print('Firebase App Check initialized')),
      
      // Initialize timezone data for notifications
      Future.sync(() {
        tz.initializeTimeZones();
        print('Timezone data initialized');
      }),
      
      // Initialize notifications (critical for user experience)
      NotificationService().initialize()
        .then((_) => print('Notification service initialized')),
    ]);

    // Initialize Firebase Analytics (non-blocking)
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    print('Firebase Analytics initialized');

    // Initialize non-critical services in background after app starts
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
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      // Initialize services in parallel that aren't needed immediately
      await Future.wait([
        // TTS service (used for voice feedback)
        TtsService().initialize()
          .then((_) => print('TTS service initialized')),
        
        // Widget service (for home screen widgets)
        WidgetService.initializeWidget()
          .then((_) => print('Widget service initialized')),
        
        // RevenueCat service (for premium features)
        RevenueCatService.initialize()
          .then((_) => print('RevenueCat service initialized')),
        
        // Ad service (for displaying ads)
        AdService.initialize()
          .then((_) => print('Ad service initialized')),
      ]);
      
      print('All non-critical services initialized');
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final languageProvider = LanguageProvider();
            languageProvider.initialize();
            return languageProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final themeProvider = ThemeProvider();
            themeProvider.initialize();
            return themeProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        
        // Task Provider with Auth dependency - Lazy loaded
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(),
          update: (_, auth, previous) {
            if (previous != null) {
              previous.updateAuth(auth);
              return previous;
            } else {
              final taskProvider = TaskProvider();
              taskProvider.updateAuth(auth);
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
            debugShowCheckedModeBanner: false,
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