import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
// Import debug widget

// Import providers
import 'providers/task_provider.dart';
import 'providers/voice_provider.dart';

// Import screens
import 'screens/login_screen.dart';
import 'screens/task_list_screen.dart';
// ignore: unused_import
import 'screens/add_task_screen.dart';
// ignore: unused_import
import 'screens/voice_input_screen.dart';
import 'screens/splash_screen.dart'; // Import the splash screen

// Import services
import 'services/notification_service.dart';
import 'services/task_service.dart';
import 'services/voice_service.dart';
import 'services/voice_parser.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize timezone data BEFORE other services
    tz.initializeTimeZones();
    // ignore: avoid_print
    print('Timezone data initialized successfully');
    
    // Initialize Firebase
    await Firebase.initializeApp();
    // ignore: avoid_print
    print('Firebase initialized successfully');
    
    // Initialize Notification Service
    final notificationService = NotificationService();
    await notificationService.initialize();
    // ignore: avoid_print
    print('Notification service initialized successfully');
    
    runApp(const MyApp());
  } catch (e) {
    // ignore: avoid_print
    print('Error during app initialization: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        // Add service providers
        Provider<TaskService>(create: (_) => TaskService()),
        Provider<VoiceService>(create: (_) => VoiceService()),
        Provider<VoiceParser>(create: (_) => VoiceParser()),
        // Add notification service as singleton
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),
      ],
      child: MaterialApp(
        title: 'WhispTask',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF1976D2),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1976D2),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        
        home: const SplashScreen(child: AuthWrapper()),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        
        // Handle authentication errors
        if (snapshot.hasError) {
          return ErrorScreen(
            error: 'Authentication Error: ${snapshot.error}',
            onRetry: () {
              // Trigger rebuild
              (context as Element).markNeedsBuild();
            },
          );
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

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6366F1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated microphone icon
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            const Text(
              'WhispTask',
              style: TextStyle(
                fontSize: 36,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Task it. Say it. Done.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 50),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Initializing your workspace...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white60,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorScreen({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6366F1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  error,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    'Try Again',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Error app for initialization failures
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhispTask - Error',
      home: ErrorScreen(
        error: 'Failed to initialize app: $error',
        onRetry: () {
          // Restart the app
          main();
        },
      ),
    );
  }
}