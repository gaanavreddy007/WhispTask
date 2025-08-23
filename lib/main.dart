import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// Import models

// Import providers
import 'providers/task_provider.dart';
import 'providers/voice_provider.dart';

// Import screens
import 'screens/login_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/add_task_screen.dart';
import 'screens/voice_input_screen.dart';

// Import services
import 'services/task_service.dart';
import 'services/voice_service.dart';
import 'services/voice_parser.dart';

// Import utils

// Import widgets

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        // Optionally add service providers if they extend ChangeNotifier
        Provider<TaskService>(create: (_) => TaskService()),
        Provider<VoiceService>(create: (_) => VoiceService()),
        Provider<VoiceParser>(create: (_) => VoiceParser()),
      ],
      child: MaterialApp(
        title: 'WhispTask',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF1976D2),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1976D2),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF1976D2),
            foregroundColor: Colors.white,
          ),
        ),
        // Define routes for navigation
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/tasks': (context) => const TaskListScreen(),
          '/add-task': (context) => const AddTaskScreen(),
          '/voice-input': (context) => const VoiceInputScreen(),
        },
        initialRoute: '/',
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        
        // Show login if not authenticated
        if (snapshot.data == null) {
          return const LoginScreen();
        }
        
        // Show main app if authenticated
        return const TaskListScreen();
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1976D2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated microphone icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.2),
              duration: const Duration(milliseconds: 1000),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: const Icon(Icons.mic, size: 80, color: Colors.white),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'WhispTask',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Task it. Say it. Done.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            const Text(
              'Initializing...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Error boundary widget for better error handling
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? errorMessage;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }

  static Widget createErrorWidget(String error) {
    return Scaffold(
      backgroundColor: const Color(0xFF1976D2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                error,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Restart app or navigate to safe state
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1976D2),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}