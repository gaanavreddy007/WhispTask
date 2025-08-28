// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

// Providers
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/voice_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/add_task_screen.dart';
import 'screens/voice_input_screen.dart';
import 'screens/account_settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/change_password_screen.dart';

// Services
import 'services/notification_service.dart';

// Widgets
import 'widgets/auth_wrapper.dart';

// Initialize notification plugin globally
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
    
    // Initialize timezone data for notifications
    tz.initializeTimeZones();
    
    // Initialize notifications
    await NotificationService().initialize();
    print('Notification service initialized');
    
  } catch (e) {
    print('Initialization error: $e');
  }
  
  runApp(const WhispTaskApp());
}

class WhispTaskApp extends StatelessWidget {
  const WhispTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider - Must be first as others depend on it
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        
        // Task Provider with Auth dependency
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
        ),
        
        // Voice Provider - Independent
        ChangeNotifierProvider(
          create: (_) => VoiceProvider(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'WhispTask',
            debugShowCheckedModeBanner: false,
            theme: _buildAppTheme(),
            
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
              '/home': (context) => const TaskListScreen(),
              '/add-task': (context) => const AddTaskScreen(),
              '/voice-input': (context) => const VoiceInputScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/account-settings': (context) => const AccountSettingsScreen(),
              '/change-password': (context) => const ChangePasswordScreen(),
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

  ThemeData _buildAppTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2), // Primary blue
        brightness: Brightness.light,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Card Theme
      cardTheme: const CardThemeData(
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 8,
        selectedItemColor: Color(0xFF1976D2),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Snackbar Theme
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF1976D2),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
      ),
      
      // Typography
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1976D2),
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFF333333),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF666666),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Color(0xFF999999),
        ),
      ),
    );
  }
}