// Ultimate error boundary to catch and handle all possible errors
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../services/sentry_service.dart';
import '../l10n/app_localizations.dart';
import 'error_recovery_system.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  final String? name;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.name,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    
    // Set up global error handler
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Log error to Sentry
      SentryService.captureException(
        details.exception,
        stackTrace: details.stack,
        hint: 'ErrorBoundary caught error in ${widget.name ?? 'Unknown'}',
      );

      return _buildErrorWidget();
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ?? _buildErrorWidget();
    }

    try {
      return widget.child;
    } catch (e, stackTrace) {
      // Log error to Sentry
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'ErrorBoundary build error in ${widget.name ?? 'Unknown'}',
      );

      setState(() {
        _hasError = true;
      });

      return widget.fallback ?? _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    const Color(0xFF0F0F23),
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ]
                : [
                    const Color(0xFF667eea),
                    const Color(0xFF764ba2),
                    const Color(0xFF1976D2),
                    const Color(0xFF1565C0),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo with error state
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.grey.shade100,
                          ],
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // App icon with error overlay
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              fit: BoxFit.contain,
                              cacheWidth: 120,
                              cacheHeight: 120,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.warning_rounded,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                          // Error indicator overlay
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade500,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.warning_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // App Name with gradient text
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.8),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'WhispTask',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Error message with fade animation
                Text(
                  'Oops! Something unexpected happened',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Don\'t worry, we\'re working on it',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Enhanced loading indicator (similar to splash screen)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.3),
                          ),
                          strokeWidth: 1.5,
                          value: 1.0,
                        ),
                      ),
                      // Animated inner ring
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                          strokeCap: StrokeCap.round,
                          value: 0.7,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Attempting to recover...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Action buttons with modern styling
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text(
                          'Try Again',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFF1976D2),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          try {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/auth-wrapper',
                              (route) => false,
                            );
                          } catch (e) {
                            // If navigation fails, try alternative route
                            try {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/home',
                                (route) => false,
                              );
                            } catch (e2) {
                              // If all navigation fails, just reset error state
                              setState(() {
                                _hasError = false;
                              });
                            }
                          }
                        },
                        icon: const Icon(Icons.home_rounded, size: 20),
                        label: const Text(
                          'Go Home',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset error state when dependencies change
    if (_hasError) {
      setState(() {
        _hasError = false;
      });
    }
  }
}

/// Ultimate safe widget wrapper
class SafeWidget extends StatelessWidget {
  final Widget Function() builder;
  final Widget? fallback;
  final String? name;

  const SafeWidget({
    super.key,
    required this.builder,
    this.fallback,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      name: name,
      fallback: fallback,
      child: Builder(
        builder: (context) {
          try {
            return builder();
          } catch (e, stackTrace) {
            // Log error
            SentryService.captureException(
              e,
              stackTrace: stackTrace,
              hint: 'SafeWidget error in ${name ?? 'Unknown'}',
            );

            // Return fallback or beautiful error widget
            return fallback ?? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.1),
                    Colors.orange.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade400, Colors.orange.shade600],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading ${name ?? 'content'}',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try refreshing',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

/// Safe async operation wrapper
class SafeAsyncBuilder<T> extends StatefulWidget {
  final Future<T> Function() future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loading;
  final Widget? error;
  final String? name;

  const SafeAsyncBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loading,
    this.error,
    this.name,
  });

  @override
  State<SafeAsyncBuilder<T>> createState() => _SafeAsyncBuilderState<T>();
}

class _SafeAsyncBuilderState<T> extends State<SafeAsyncBuilder<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.future();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        try {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return widget.loading ?? const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Log error
            SentryService.captureException(
              snapshot.error!,
              stackTrace: snapshot.stackTrace,
              hint: 'SafeAsyncBuilder error in ${widget.name ?? 'Unknown'}',
            );

            return widget.error ?? Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.1),
                    Colors.red.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading ${widget.name ?? 'data'}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Something went wrong while loading',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _future = widget.future();
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text(
                        'Try Again',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData) {
            return widget.builder(context, snapshot.data as T);
          }

          return widget.error ?? const SizedBox.shrink();
        } catch (e, stackTrace) {
          // Log error
          SentryService.captureException(
            e,
            stackTrace: stackTrace,
            hint: 'SafeAsyncBuilder build error in ${widget.name ?? 'Unknown'}',
          );

          return Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Error building content',
              style: TextStyle(color: Colors.red),
            ),
          );
        }
      },
    );
  }
}
