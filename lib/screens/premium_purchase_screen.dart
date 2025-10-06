// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/web_payment_service.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';

class PremiumPurchaseScreen extends StatefulWidget {
  const PremiumPurchaseScreen({super.key});

  @override
  State<PremiumPurchaseScreen> createState() => _PremiumPurchaseScreenState();
}

class _PremiumPurchaseScreenState extends State<PremiumPurchaseScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _isPremium = false;
  
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _floatingAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));
    
    _animationController.forward();
    _floatingController.repeat(reverse: true);
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await WebPaymentService.isPremiumUser();
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
      });
    }
  }

  Future<void> _purchaseMonthly() async {
    setState(() {
      _isLoading = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final success = await WebPaymentService.purchaseMonthlyPremium(context);
      if (success) {
        // Update auth provider premium status
        final authProvider = context.read<AuthProvider>();
        await authProvider.checkPremiumStatus();
        
        HapticFeedback.lightImpact();
        
        ScaffoldMessenger.of(context).showSnackBar(
          _buildEnhancedSnackBar(
            AppLocalizations.of(context).monthlyPremiumActivated,
            Colors.green,
            Icons.check_circle,
          ),
        );
        
        Navigator.pop(context, true);
      } else {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          _buildEnhancedSnackBar(
            AppLocalizations.of(context).purchaseFailed,
            Colors.red,
            Icons.error,
          ),
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        _buildEnhancedSnackBar(
          '${AppLocalizations.of(context).error}: $e',
          Colors.red,
          Icons.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _purchaseYearly() async {
    setState(() {
      _isLoading = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final success = await WebPaymentService.purchaseYearlyPremium(context);
      if (success) {
        // Update auth provider premium status
        final authProvider = context.read<AuthProvider>();
        await authProvider.checkPremiumStatus();
        
        HapticFeedback.lightImpact();
        
        ScaffoldMessenger.of(context).showSnackBar(
          _buildEnhancedSnackBar(
            AppLocalizations.of(context).yearlyPremiumActivated,
            Colors.green,
            Icons.check_circle,
          ),
        );
        
        Navigator.pop(context, true);
      } else {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          _buildEnhancedSnackBar(
            AppLocalizations.of(context).purchaseFailed,
            Colors.red,
            Icons.error,
          ),
        );
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        _buildEnhancedSnackBar(
          '${AppLocalizations.of(context).error}: $e',
          Colors.red,
          Icons.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
    });

    HapticFeedback.lightImpact();

    try {
      await WebPaymentService.restorePurchases();
      await _checkPremiumStatus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        _buildEnhancedSnackBar(
          AppLocalizations.of(context).purchasesRestored,
          Colors.blue,
          Icons.restore,
        ),
      );
    } catch (e) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        _buildEnhancedSnackBar(
          '${AppLocalizations.of(context).failedToRestore}: $e',
          Colors.red,
          Icons.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  SnackBar _buildEnhancedSnackBar(String message, Color color, IconData icon) {
    return SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isPremium) {
      return _buildPremiumActiveScreen();
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildProfileStyleAppBar(theme),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeroSection(),
              _buildFeaturesSection(),
              _buildPricingSection(),
              _buildFooterSection(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildProfileStyleAppBar(ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF1976D2), // Blue header
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
        ),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Container(
                color: Colors.white,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).upgradeToPremium,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  Widget _buildHeroSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_floatingAnimation, _shimmerAnimation]),
      builder: (context, child) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      const Color(0xFF1976D2).withOpacity(0.8),
                      const Color(0xFF1565C0).withOpacity(0.6),
                    ]
                  : [
                      const Color(0xFFFFB300).withOpacity(0.8),
                      const Color(0xFFF57C00).withOpacity(0.6),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Floating premium icon
              Transform.translate(
                offset: Offset(0, _floatingAnimation.value),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 20,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: const [
                        Color(0xFFFFD700),
                        Color(0xFFFFA000),
                      ],
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.workspace_premium,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title with shimmer effect
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.white.withOpacity(0.8),
                          Colors.white,
                        ],
                        stops: [
                          0.0,
                          _shimmerAnimation.value.clamp(0.0, 1.0),
                          1.0,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        AppLocalizations.of(context).whispTaskPremium,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Text(
                      AppLocalizations.of(context).unlockFullPotential,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturesSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? theme.colorScheme.surfaceVariant
            : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: const [
                        Color(0xFFFFB300),
                        Color(0xFFF57C00),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Premium Features',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode 
                        ? theme.colorScheme.onSurfaceVariant
                        : Colors.grey[800],
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            _buildEnhancedFeatureItem(
              Icons.record_voice_over,
              AppLocalizations.of(context).customVoicePacks,
              AppLocalizations.of(context).customVoicePacksDesc,
              const Color(0xFF1E88E5),
            ),
            _buildEnhancedFeatureItem(
              Icons.cloud_off,
              AppLocalizations.of(context).offlineMode,
              AppLocalizations.of(context).offlineModeDesc,
              const Color(0xFF43A047),
            ),
            _buildEnhancedFeatureItem(
              Icons.label,
              AppLocalizations.of(context).smartTags,
              AppLocalizations.of(context).smartTagsDesc,
              const Color(0xFFE53935),
            ),
            _buildEnhancedFeatureItem(
              Icons.palette,
              AppLocalizations.of(context).customThemes,
              AppLocalizations.of(context).customThemesDesc,
              const Color(0xFF8E24AA),
            ),
            _buildEnhancedFeatureItem(
              Icons.analytics,
              AppLocalizations.of(context).advancedAnalytics,
              AppLocalizations.of(context).advancedAnalyticsDesc,
              const Color(0xFFFF9800),
            ),
            _buildEnhancedFeatureItem(
              Icons.notifications_off,
              AppLocalizations.of(context).noAds,
              AppLocalizations.of(context).noAdsDesc,
              const Color(0xFF00ACC1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedFeatureItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode 
                        ? theme.colorScheme.onSurfaceVariant
                        : Colors.grey[800],
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDarkMode 
                        ? theme.colorScheme.onSurfaceVariant.withOpacity(0.8)
                        : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.2)
                  : theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.3)
                    : theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              AppLocalizations.of(context).chooseYourPlan,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDarkMode 
                    ? Colors.white
                    : theme.colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Monthly Plan
          _buildEnhancedPricingCard(
            title: AppLocalizations.of(context).monthly,
            price: '₹149',
            period: '/${AppLocalizations.of(context).month}',
            features: [
              AppLocalizations.of(context).allPremiumFeatures,
              AppLocalizations.of(context).cancelAnytime,
              AppLocalizations.of(context).instantActivation,
            ],
            onTap: _purchaseMonthly,
            isPopular: false,
            gradientColors: [
              const Color(0xFF42A5F5),
              const Color(0xFF1E88E5),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Yearly Plan
          _buildEnhancedPricingCard(
            title: AppLocalizations.of(context).yearly,
            price: '₹1,199',
            period: '/${AppLocalizations.of(context).year}',
            originalPrice: '₹1,788',
            features: [
              AppLocalizations.of(context).allPremiumFeatures,
              'Save ₹589 yearly!',
              AppLocalizations.of(context).prioritySupport,
              AppLocalizations.of(context).earlyAccess,
            ],
            onTap: _purchaseYearly,
            isPopular: false,
            gradientColors: [
              const Color(0xFFFFD700),
              const Color(0xFFFFB300),
              const Color(0xFFF57C00),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPricingCard({
    required String title,
    required String price,
    required String period,
    String? originalPrice,
    required List<String> features,
    required VoidCallback onTap,
    required bool isPopular,
    required List<Color> gradientColors,
  }) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isPopular ? 1.05 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: gradientColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: isPopular ? 2 : 0,
                ),
                if (isPopular)
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 30,
                    spreadRadius: -10,
                  ),
              ],
            ),
            child: Stack(
              children: [
                if (isPopular)
                  Positioned(
                    top: -2,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: const [
                            Color(0xFFE91E63),
                            Color(0xFFAD1457),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE91E63).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context).popular,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                Container(
                  margin: EdgeInsets.only(top: isPopular ? 16 : 0),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradientColors),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isPopular ? Icons.workspace_premium : Icons.card_membership,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey[800],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: gradientColors,
                            ).createShader(bounds),
                            child: Text(
                              price,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 4),
                            child: Text(
                              period,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (originalPrice != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Text(
                                originalPrice,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red[600],
                                  decoration: TextDecoration.lineThrough,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      ...features.asMap().entries.map((entry) {
                        final index = entry.key;
                        final feature = entry.value;
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(50 * (1 - value), 0),
                              child: Opacity(
                                opacity: value,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: gradientColors),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          feature,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                      
                      const SizedBox(height: 24),
                      
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: gradientColors.first.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () {
                            HapticFeedback.mediumImpact();
                            onTap();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Processing...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Choose $title',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Restore Purchases Button
          Container(
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.2)
                  : theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.3)
                    : theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextButton.icon(
              onPressed: _isLoading ? null : () {
                HapticFeedback.lightImpact();
                _restorePurchases();
              },
              icon: Icon(
                Icons.restore,
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.9)
                    : theme.colorScheme.primary,
                size: 20,
              ),
              label: Text(
                AppLocalizations.of(context).restorePurchases,
                style: TextStyle(
                  color: isDarkMode 
                      ? Colors.white.withOpacity(0.9)
                      : theme.colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Terms and Privacy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.1)
                  : theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.2)
                    : theme.colorScheme.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              AppLocalizations.of(context).termsAndPrivacy,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.8)
                    : theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildPremiumActiveAppBar(ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF4CAF50), // Green header for premium active
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
        ),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Container(
                color: Colors.white,
                child: const Icon(
                  Icons.verified_rounded,
                  size: 20,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).premiumActive,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ],
      ),
      centerTitle: false,
    );
  }

  Widget _buildPremiumActiveScreen() {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildPremiumActiveAppBar(theme),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Main Content
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Success Icon
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1000),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.white.withOpacity(0.9),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.8),
                                      blurRadius: 20,
                                      spreadRadius: -10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  size: 80,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 40),

                        // Title
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 800),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 50 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.white.withOpacity(0.8),
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    AppLocalizations.of(context).premiumActive,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Description
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1000),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context).premiumActiveDesc,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                      height: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 40),

                        // Continue Button
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1200),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.white.withOpacity(0.9),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context).continue_,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF4CAF50),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
      )
    );
  }
}