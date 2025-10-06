// Create a new file: lib/screens/splash_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
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
    
    // Main animation controller - ultra-fast for instant startup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800), // Ultra-fast
      vsync: this,
    );
    
    // Rotation controller for background elements - ultra-fast
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8), // Ultra-fast
      vsync: this,
    );
    
    // Particle animation controller - ultra-fast
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1000), // Ultra-fast
      vsync: this,
    );
    
    // Pulse controller for logo glow - ultra-fast
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600), // Ultra-fast
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
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );
    
    // Slide up animation for text
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
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
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
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
    
    // Navigate to main app after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth-wrapper');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
        child: Stack(
          children: [
            // Animated background shapes
            ...List.generate(6, (index) => _buildFloatingShape(index, size)),
            
            // Particle effects
            ...List.generate(20, (index) => _buildParticle(index, size)),
            
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
                        children: [
                          // Logo with enhanced effects
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    // Outer glow
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3 * _logoGlowAnimation.value),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                    // Inner shadow for depth
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(32),
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
                                          padding: const EdgeInsets.all(20.0),
                                          child: Image.asset(
                                            'assets/images/app_icon.png',  
                                            fit: BoxFit.contain,
                                            cacheWidth: 140,
                                            cacheHeight: 140,
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
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: const Icon(
                                                  Icons.task_alt_rounded,
                                                  size: 70,
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
                          
                          const SizedBox(height: 40),
                          
                          // App Name with better contrast
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context).whispTask,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.7),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Tagline with better contrast
                          Opacity(
                            opacity: _fadeAnimation.value * 0.9,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                AppLocalizations.of(context).voicePoweredTaskManagement,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 1,
                                  height: 1.4,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 60),
                          
                          // Enhanced loading indicator
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer ring
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withOpacity(0.3),
                                    ),
                                    strokeWidth: 2,
                                    value: 1.0,
                                  ),
                                ),
                                // Animated inner ring
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: AnimatedBuilder(
                                    animation: _rotationController,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _rotationAnimation.value,
                                        child: CircularProgressIndicator(
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                          strokeWidth: 3,
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
                          
                          const SizedBox(height: 20),
                          
                          // Loading text with pulse animation
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: 0.5 + (0.3 * _pulseAnimation.value),
                                child: Text(
                                  AppLocalizations.of(context).loading,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFloatingShape(int index, Size size) {
    // Pre-calculate colors for better performance
    const colors = [
      Color(0x0DFFFFFF), // Colors.white.withOpacity(0.05)
      Color(0x08FFFFFF), // Colors.white.withOpacity(0.03)
      Color(0x1400FFFF), // Colors.cyan.withOpacity(0.08)
      Color(0x0F0000FF), // Colors.blue.withOpacity(0.06)
      Color(0x0A800080), // Colors.purple.withOpacity(0.04)
      Color(0x0DFFC0CB), // Colors.pink.withOpacity(0.05)
    ];
    
    final shapes = [
      BoxShape.circle,
      BoxShape.rectangle,
    ];
    
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _particleController]),
      builder: (context, child) {
        final rotation = _rotationAnimation.value + (index * 0.5);
        final float = math.sin(_particleAnimation.value * math.pi + index) * 20;
        
        return Positioned(
          left: (size.width * (0.1 + (index * 0.15))) + 
                (math.cos(rotation) * (50 + index * 10)),
          top: (size.height * (0.1 + (index * 0.12))) + 
               (math.sin(rotation) * (30 + index * 8)) + float,
          child: Transform.rotate(
            angle: rotation * (index.isOdd ? -1 : 1),
            child: Container(
              width: 20 + (index * 8).toDouble(),
              height: 20 + (index * 8).toDouble(),
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: shapes[index % shapes.length],
                borderRadius: shapes[index % shapes.length] == BoxShape.rectangle
                    ? BorderRadius.circular(8)
                    : null,
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
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