// ignore_for_file: avoid_print, deprecated_member_use, unused_field

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class RevenueCatService {
  static const String _premiumKey = 'is_premium_user';
  static const String _premiumExpiryKey = 'premium_expiry_date';
  
  // RevenueCat Configuration
  static const String _revenueCatApiKey = 'goog_qzJojZDwCOLwVIdQOddGRnoWLwd';
  static const String _revenueCatAppId = 'app6d8de76b03';
  
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Configure RevenueCat
      await Purchases.setLogLevel(LogLevel.info);
      
      PurchasesConfiguration configuration = PurchasesConfiguration(_revenueCatApiKey);
      await Purchases.configure(configuration);
      
      _isInitialized = true;
      print('RevenueCat initialized successfully with App ID: $_revenueCatAppId');
    } catch (e) {
      print('Failed to initialize RevenueCat: $e');
      // Log to Sentry
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('service', 'revenue_cat');
          scope.setTag('operation', 'initialize');
          scope.level = SentryLevel.warning;
        },
      );
      // Fallback to local premium service
      _isInitialized = true;
      print('Using local premium service as fallback');
    }
  }
  
  static Future<bool> isPremiumUser() async {
    try {
      // Try RevenueCat first
      if (_isInitialized) {
        try {
          CustomerInfo customerInfo = await Purchases.getCustomerInfo();
          bool hasActiveSubscription = customerInfo.entitlements.active.isNotEmpty;
          
          if (hasActiveSubscription) {
            // Update local storage for consistency
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_premiumKey, true);
            return true;
          }
        } catch (e) {
          print('RevenueCat check failed, falling back to local: $e');
          // Log to Sentry for monitoring
          await Sentry.captureException(
            e,
            stackTrace: StackTrace.current,
            withScope: (scope) {
              scope.setTag('service', 'revenue_cat');
              scope.setTag('operation', 'check_premium');
              scope.level = SentryLevel.info;
            },
          );
        }
      }
      
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      bool isPremium = prefs.getBool(_premiumKey) ?? false;
      
      if (isPremium) {
        // Check if premium subscription is still valid
        int? expiryTimestamp = prefs.getInt(_premiumExpiryKey);
        if (expiryTimestamp != null) {
          DateTime expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
          if (DateTime.now().isAfter(expiryDate)) {
            // Premium expired, remove premium status
            await prefs.setBool(_premiumKey, false);
            await prefs.remove(_premiumExpiryKey);
            return false;
          }
        }
      }
      
      return isPremium;
    } catch (e) {
      print('Failed to check premium status: $e');
      return false;
    }
  }
  
  static Future<bool> purchaseMonthlyPremium() async {
    try {
      if (_isInitialized) {
        try {
          // Get available offerings from RevenueCat
          Offerings offerings = await Purchases.getOfferings();
          
          if (offerings.current != null) {
            // Look for monthly package
            Package? monthlyPackage = offerings.current!.monthly;
            
            if (monthlyPackage != null) {
              PurchaseResult purchaseResult = await Purchases.purchasePackage(monthlyPackage);
              CustomerInfo customerInfo = purchaseResult.customerInfo;
              
              if (customerInfo.entitlements.active.isNotEmpty) {
                // Update local storage
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_premiumKey, true);
                print('Monthly premium purchased successfully via RevenueCat');
                return true;
              }
            }
          }
        } catch (e) {
          print('RevenueCat purchase failed, using local fallback: $e');
          // Log purchase failures to Sentry
          await Sentry.captureException(
            e,
            stackTrace: StackTrace.current,
            withScope: (scope) {
              scope.setTag('service', 'revenue_cat');
              scope.setTag('operation', 'purchase_monthly');
              scope.level = SentryLevel.warning;
              scope.setExtra('purchase_type', 'monthly');
              scope.setExtra('fallback_used', true);
            },
          );
        }
      }
      
      // Fallback to local simulation
      final prefs = await SharedPreferences.getInstance();
      DateTime expiryDate = DateTime.now().add(const Duration(days: 30));
      await prefs.setBool(_premiumKey, true);
      await prefs.setInt(_premiumExpiryKey, expiryDate.millisecondsSinceEpoch);
      
      print('Monthly premium activated until: $expiryDate (local)');
      return true;
    } catch (e) {
      print('Monthly purchase failed: $e');
      return false;
    }
  }
  
  static Future<bool> purchaseYearlyPremium() async {
    try {
      if (_isInitialized) {
        try {
          // Get available offerings from RevenueCat
          Offerings offerings = await Purchases.getOfferings();
          
          if (offerings.current != null) {
            // Look for annual package
            Package? yearlyPackage = offerings.current!.annual;
            
            if (yearlyPackage != null) {
              PurchaseResult purchaseResult = await Purchases.purchasePackage(yearlyPackage);
              CustomerInfo customerInfo = purchaseResult.customerInfo;
              
              if (customerInfo.entitlements.active.isNotEmpty) {
                // Update local storage
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_premiumKey, true);
                print('Yearly premium purchased successfully via RevenueCat');
                return true;
              }
            }
          }
        } catch (e) {
          print('RevenueCat purchase failed, using local fallback: $e');
          // Log purchase failures to Sentry
          await Sentry.captureException(
            e,
            stackTrace: StackTrace.current,
            withScope: (scope) {
              scope.setTag('service', 'revenue_cat');
              scope.setTag('operation', 'purchase_yearly');
              scope.level = SentryLevel.warning;
              scope.setExtra('purchase_type', 'yearly');
              scope.setExtra('fallback_used', true);
            },
          );
        }
      }
      
      // Fallback to local simulation
      final prefs = await SharedPreferences.getInstance();
      DateTime expiryDate = DateTime.now().add(const Duration(days: 365));
      await prefs.setBool(_premiumKey, true);
      await prefs.setInt(_premiumExpiryKey, expiryDate.millisecondsSinceEpoch);
      
      print('Yearly premium activated until: $expiryDate (local)');
      return true;
    } catch (e) {
      print('Yearly purchase failed: $e');
      return false;
    }
  }
  
  static Future<void> restorePurchases() async {
    try {
      if (_isInitialized) {
        try {
          CustomerInfo customerInfo = await Purchases.restorePurchases();
          
          if (customerInfo.entitlements.active.isNotEmpty) {
            // Update local storage
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_premiumKey, true);
            print('Purchases restored successfully via RevenueCat');
            return;
          }
        } catch (e) {
          print('RevenueCat restore failed: $e');
          // Log restore failures to Sentry
          await Sentry.captureException(
            e,
            stackTrace: StackTrace.current,
            withScope: (scope) {
              scope.setTag('service', 'revenue_cat');
              scope.setTag('operation', 'restore_purchases');
              scope.level = SentryLevel.info;
            },
          );
        }
      }
      
      // Fallback - just check current premium status
      bool isPremium = await isPremiumUser();
      print('Premium status restored (local): $isPremium');
    } catch (e) {
      print('Failed to restore purchases: $e');
    }
  }
  
  static Future<void> revokePremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, false);
      await prefs.remove(_premiumExpiryKey);
      print('Premium status revoked');
    } catch (e) {
      print('Failed to revoke premium: $e');
    }
  }
}
