// ignore_for_file: unnecessary_import, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/biometric_service.dart';
import '../l10n/app_localizations.dart';

class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  
  const BiometricLockScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  
  bool _isAuthenticating = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    _pulseController.repeat(reverse: true);
    
    // Auto-trigger biometric authentication
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateWithBiometrics();
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }
  
  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });
    
    try {
      final bool isAuthenticated = await BiometricService.authenticate(
        reason: 'Please authenticate to access WhispTask',
      );
      
      if (isAuthenticated) {
        widget.onAuthenticated();
      } else {
        setState(() {
          _errorMessage = 'Authentication failed. Please try again.';
          _isAuthenticating = false;
        });
        _shakeController.forward().then((_) => _shakeController.reset());
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isAuthenticating = false;
      });
      _shakeController.forward().then((_) => _shakeController.reset());
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.surface,
              colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 64,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                // App Logo/Title
                Text(
                  AppLocalizations.of(context).whispTask,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Secure Access Required',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 64),
                
                // Biometric Icon with Animation
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    colorScheme.primary.withOpacity(0.1),
                                    colorScheme.primary.withOpacity(0.05),
                                  ],
                                ),
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.fingerprint,
                                size: 72,
                                color: _isAuthenticating 
                                    ? colorScheme.primary
                                    : colorScheme.primary.withOpacity(0.7),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Status Text
                if (_isAuthenticating)
                  Column(
                    children: [
                      CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Authenticating...',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  )
                else if (_errorMessage.isNotEmpty)
                  Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.error,
                        size: 32,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _authenticateWithBiometrics,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Touch the fingerprint sensor or use Face ID to unlock WhispTask',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.8),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _authenticateWithBiometrics,
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Authenticate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 64),
                
                // Alternative Access (if needed)
                TextButton(
                  onPressed: () {
                    // For now, just show a message that biometric is required
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Biometric authentication is required to access this app'),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                  },
                  child: Text(
                    'Need help?',
                    style: TextStyle(
                      color: colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
