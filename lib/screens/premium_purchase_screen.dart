// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/revenue_cat_service.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';

class PremiumPurchaseScreen extends StatefulWidget {
  const PremiumPurchaseScreen({super.key});

  @override
  State<PremiumPurchaseScreen> createState() => _PremiumPurchaseScreenState();
}

class _PremiumPurchaseScreenState extends State<PremiumPurchaseScreen> {
  bool _isLoading = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await RevenueCatService.isPremiumUser();
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

    try {
      final success = await RevenueCatService.purchaseMonthlyPremium();
      if (success) {
        // Update auth provider premium status
        final authProvider = context.read<AuthProvider>();
        await authProvider.checkPremiumStatus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).monthlyPremiumActivated),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).purchaseFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).error}: $e'),
          backgroundColor: Colors.red,
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

    try {
      final success = await RevenueCatService.purchaseYearlyPremium();
      if (success) {
        // Update auth provider premium status
        final authProvider = context.read<AuthProvider>();
        await authProvider.checkPremiumStatus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).yearlyPremiumActivated),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).purchaseFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).error}: $e'),
          backgroundColor: Colors.red,
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

    try {
      await RevenueCatService.restorePurchases();
      await _checkPremiumStatus();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).purchasesRestored),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).failedToRestore}: $e'),
          backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    if (_isPremium) {
      return _buildPremiumActiveScreen();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).upgradeToPremium),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.amber, Colors.amber.shade300],
                ),
              ),
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.star,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).whispTaskPremium,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).unlockFullPotential,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Features Section
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium Features',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  _buildFeatureItem(
                    Icons.record_voice_over,
                    AppLocalizations.of(context).customVoicePacks,
                    AppLocalizations.of(context).customVoicePacksDesc,
                  ),
                  _buildFeatureItem(
                    Icons.cloud_off,
                    AppLocalizations.of(context).offlineMode,
                    AppLocalizations.of(context).offlineModeDesc,
                  ),
                  _buildFeatureItem(
                    Icons.label,
                    AppLocalizations.of(context).smartTags,
                    AppLocalizations.of(context).smartTagsDesc,
                  ),
                  _buildFeatureItem(
                    Icons.palette,
                    AppLocalizations.of(context).customThemes,
                    AppLocalizations.of(context).customThemesDesc,
                  ),
                  _buildFeatureItem(
                    Icons.analytics,
                    AppLocalizations.of(context).advancedAnalytics,
                    AppLocalizations.of(context).advancedAnalyticsDesc,
                  ),
                  _buildFeatureItem(
                    Icons.notifications_none,
                    AppLocalizations.of(context).noAds,
                    AppLocalizations.of(context).noAdsDesc,
                  ),
                ],
              ),
            ),

            // Pricing Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context).chooseYourPlan,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Monthly Plan
                  _buildPricingCard(
                    title: AppLocalizations.of(context).monthly,
                    price: '\$4.99',
                    period: AppLocalizations.of(context).month,
                    features: [
                      AppLocalizations.of(context).allPremiumFeatures,
                      AppLocalizations.of(context).cancelAnytime,
                      AppLocalizations.of(context).instantActivation,
                    ],
                    onTap: _purchaseMonthly,
                    isPopular: false,
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Yearly Plan
                  _buildPricingCard(
                    title: AppLocalizations.of(context).yearly,
                    price: '\$39.99',
                    period: AppLocalizations.of(context).year,
                    originalPrice: '\$59.88',
                    features: [
                      AppLocalizations.of(context).allPremiumFeatures,
                      AppLocalizations.of(context).saveVsMonthly,
                      AppLocalizations.of(context).prioritySupport,
                      AppLocalizations.of(context).earlyAccess,
                    ],
                    onTap: _purchaseYearly,
                    isPopular: true,
                  ),
                ],
              ),
            ),

            // Restore Purchases Button
            Padding(
              padding: EdgeInsets.all(24),
              child: TextButton(
                onPressed: _isLoading ? null : _restorePurchases,
                child: Text(
                  AppLocalizations.of(context).restorePurchases,
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Terms and Privacy
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                AppLocalizations.of(context).termsAndPrivacy,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumActiveScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).premiumActive),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
              SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).premiumActive,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).premiumActiveDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(AppLocalizations.of(context).continue_),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.amber[700],
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required String title,
    required String price,
    required String period,
    String? originalPrice,
    required List<String> features,
    required VoidCallback onTap,
    required bool isPopular,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isPopular ? Colors.amber : Colors.grey[300]!,
          width: isPopular ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).popular,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                    Text(
                      period,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (originalPrice != null) ...[
                      SizedBox(width: 8),
                      Text(
                        originalPrice,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 16),
                ...features.map((feature) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? Colors.amber : Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Choose $title',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
