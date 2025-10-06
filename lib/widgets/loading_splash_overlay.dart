// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'dart:math' as math;

class LoadingSplashOverlay extends StatefulWidget {
  final String? message;
  final bool showMessage;
  final VoidCallback? onTap;
  final bool isFullScreen;
  final Color? backgroundColor;

  const LoadingSplashOverlay({
    super.key,
    this.message,
    this.showMessage = true,
    this.onTap,
    this.isFullScreen = true,
    this.backgroundColor,
  });

  @override
  State<LoadingSplashOverlay> createState() => _LoadingSplashOverlayState();
}

class _LoadingSplashOverlayState extends State<LoadingSplashOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _rotationController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _logoGlowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Rotation controller for background elements
    _rotationController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    
    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Pulse controller for logo glow
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Fade in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    // Scale animation with bounce effect
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );
    
    // Slide up animation for text
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    
    // Rotation animation for background elements
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
    
    // Particle floating animation
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );
    
    // Pulse animation for logo glow
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Logo glow animation
    _logoGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start all animations
    _animationController.forward();
    _rotationController.repeat();
    _particleController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _getSafeAppName(BuildContext context) {
    try {
      return AppLocalizations.of(context).whispTask;
    } catch (e) {
      return 'WhispTask';
    }
  }

  String _getSafeTagline(BuildContext context) {
    try {
      return AppLocalizations.of(context).voicePoweredTaskManagement;
    } catch (e) {
      return 'Voice-Powered Task Management';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    Widget content = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.backgroundColor != null 
            ? [widget.backgroundColor!, widget.backgroundColor!]
            : isDarkMode 
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
      child: Stack(
        children: [
          // Animated background shapes (fewer for overlay)
          if (widget.isFullScreen) 
            ...List.generate(4, (index) => _buildFloatingShape(index, size)),
          
          // Particle effects (fewer for overlay)
          if (widget.isFullScreen)
            ...List.generate(10, (index) => _buildParticle(index, size)),
          
          // Main content
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _animationController,
                _pulseController,
              ]),
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo with enhanced effects
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: widget.isFullScreen ? 120 : 80,
                              height: widget.isFullScreen ? 120 : 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(widget.isFullScreen ? 28 : 20),
                                boxShadow: [
                                  // Outer glow
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.2 * _logoGlowAnimation.value),
                                    blurRadius: widget.isFullScreen ? 30 : 20,
                                    spreadRadius: widget.isFullScreen ? 8 : 5,
                                  ),
                                  // Inner shadow for depth
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: widget.isFullScreen ? 15 : 10,
                                    offset: Offset(0, widget.isFullScreen ? 8 : 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(widget.isFullScreen ? 28 : 20),
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
                                      // Shimmer effect
                                      AnimatedBuilder(
                                        animation: _rotationController,
                                        builder: (context, child) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.white.withOpacity(0.1),
                                                  Colors.transparent,
                                                ],
                                                transform: GradientRotation(_rotationAnimation.value),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // App icon/logo
                                      Padding(
                                        padding: EdgeInsets.all(widget.isFullScreen ? 16.0 : 12.0),
                                        child: Image.asset(
                                            'assets/images/app_icon.png',  
                                            fit: BoxFit.contain,
                                            cacheWidth: widget.isFullScreen ? 120 : 80,
                                            cacheHeight: widget.isFullScreen ? 120 : 80,
                                            errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: isDarkMode
                                                    ? [Colors.cyan.shade300, Colors.cyan.shade600]
                                                    : [const Color(0xFF1976D2), const Color(0xFF1565C0)],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.task_alt_rounded,
                                                size: widget.isFullScreen ? 60 : 40,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        if (widget.isFullScreen) ...[
                          const SizedBox(height: 32),
                          
                          // App Name with gradient text
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.8),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              _getSafeAppName(context),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Tagline with fade animation
                          Opacity(
                            opacity: _fadeAnimation.value * 0.9,
                            child: Text(
                              _getSafeTagline(context),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.5,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        
                        SizedBox(height: widget.isFullScreen ? 40 : 24),
                        
                        // Enhanced loading indicator
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
                                width: widget.isFullScreen ? 32 : 24,
                                height: widget.isFullScreen ? 32 : 24,
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
                                width: widget.isFullScreen ? 32 : 24,
                                height: widget.isFullScreen ? 32 : 24,
                                child: AnimatedBuilder(
                                  animation: _rotationController,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: _rotationAnimation.value,
                                      child: CircularProgressIndicator(
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2,
                                        strokeCap: StrokeCap.round,
                                        value: 0.7,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        if (widget.showMessage) ...[
                          SizedBox(height: widget.isFullScreen ? 16 : 12),
                          
                          // Loading text with pulse animation
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: 0.6 + (0.2 * _pulseAnimation.value),
                                child: Text(
                                  widget.message ?? 'Loading...',
                                  style: TextStyle(
                                    fontSize: widget.isFullScreen ? 12 : 10,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.onTap != null) {
      content = GestureDetector(
        onTap: widget.onTap,
        child: content,
      );
    }

    return widget.isFullScreen 
      ? Scaffold(body: content)
      : Material(
          color: Colors.transparent,
          child: content,
        );
  }
  
  Widget _buildFloatingShape(int index, Size size) {
    // Pre-calculate colors to avoid repeated opacity calculations
    const colors = [
      Color(0x0AFFFFFF), // Colors.white.withOpacity(0.04)
      Color(0x05FFFFFF), // Colors.white.withOpacity(0.02)
      Color(0x0F00FFFF), // Colors.cyan.withOpacity(0.06)
      Color(0x0A0000FF), // Colors.blue.withOpacity(0.04)
    ];
    
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _particleController]),
      builder: (context, child) {
        final rotation = _rotationAnimation.value + (index * 0.5);
        final float = math.sin(_particleAnimation.value * math.pi + index) * 15;
        
        return Positioned(
          left: (size.width * (0.1 + (index * 0.2))) + 
                (math.cos(rotation) * (40 + index * 8)),
          top: (size.height * (0.1 + (index * 0.15))) + 
               (math.sin(rotation) * (25 + index * 6)) + float,
          child: Transform.rotate(
            angle: rotation * (index.isOdd ? -1 : 1),
            child: Container(
              width: 16 + (index * 6).toDouble(),
              height: 16 + (index * 6).toDouble(),
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: index.isEven ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: index.isEven ? null : BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 0.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildParticle(int index, Size size) {
    // Pre-calculate particle properties for better performance
    const particleColor = Color(0x99FFFFFF); // Colors.white.withOpacity(0.6)
    const shadowColor = Color(0x33FFFFFF); // Colors.white.withOpacity(0.2)
    
    return AnimatedBuilder(
      animation: Listenable.merge([_particleController, _rotationController]),
      builder: (context, child) {
        final animationOffset = (index * 0.1) % 1.0;
        final progress = (_particleAnimation.value + animationOffset) % 1.0;
        final rotation = _rotationAnimation.value * (index.isOdd ? 1 : -1);
        
        final x = size.width * (0.1 + (index * 0.08) % 0.8) + 
                  (math.cos(rotation + index) * 20);
        final y = size.height * progress;
        
        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: (1.0 - progress) * 0.4,
            child: Container(
              width: 1.5 + (index % 2).toDouble(),
              height: 1.5 + (index % 2).toDouble(),
              decoration: const BoxDecoration(
                color: particleColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 2,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Helper class for showing splash overlay
class SplashOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context, {
    String? message,
    bool showMessage = true,
    VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    try {
      hide(); // Remove any existing overlay
      
      _overlayEntry = OverlayEntry(
        builder: (context) => LoadingSplashOverlay(
          message: message,
          showMessage: showMessage,
          onTap: onTap,
          isFullScreen: false,
          backgroundColor: backgroundColor,
        ),
      );
      
      final overlay = Overlay.of(context);
      overlay.insert(_overlayEntry!);
    } catch (e) {
      print('Error showing splash overlay: $e');
    }
  }

  static void hide() {
    try {
      _overlayEntry?.remove();
      _overlayEntry = null;
    } catch (e) {
      print('Error hiding splash overlay: $e');
      _overlayEntry = null; // Reset anyway
    }
  }
}
