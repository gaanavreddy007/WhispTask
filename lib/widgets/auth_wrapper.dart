// lib/widgets/auth_wrapper.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import '../providers/auth_provider.dart';

// Screens
import '../screens/login_screen.dart';
import '../screens/task_list_screen.dart';

// Localization
import '../l10n/app_localizations.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize auth when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.initializeAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while initializing
        if (!authProvider.isInitialized) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(localizations.loading),
                ],
              ),
            ),
          );
        }

        // Show appropriate screen based on auth state
        if (authProvider.isLoggedIn && authProvider.user != null) {
          return const TaskListScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}