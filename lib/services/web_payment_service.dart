// ignore_for_file: avoid_print, deprecated_member_use, unused_field, use_build_context_synchronously, unnecessary_import

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class WebPaymentService {
  static const String _premiumKey = 'is_premium_user';
  static const String _premiumExpiryKey = 'premium_expiry_date';
  
  // Web Payment Configuration - Using local demo files for testing
  static const String _paymentBaseUrl = 'file:///c:/Gaanav/Internship/Task%201/whispTask';
  static const String _monthlyPlanUrl = '$_paymentBaseUrl/demo_payment.html?plan=monthly';
  static const String _yearlyPlanUrl = '$_paymentBaseUrl/demo_payment.html?plan=yearly';
  static const String _successUrl = '$_paymentBaseUrl/payment_success.html';
  static const String _cancelUrl = '$_paymentBaseUrl/payment_cancel.html';
  
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize WebView
      _isInitialized = true;
      print('WebPaymentService initialized successfully');
    } catch (e) {
      print('Failed to initialize WebPaymentService: $e');
      // Log to Sentry
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('service', 'web_payment');
          scope.setTag('operation', 'initialize');
          scope.level = SentryLevel.warning;
        },
      );
      _isInitialized = true;
      print('Using local premium service as fallback');
    }
  }
  
  static Future<bool> isPremiumUser() async {
    try {
      // Check local storage for premium status
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
  
  /// Open web payment for monthly premium
  static Future<bool> purchaseMonthlyPremium(BuildContext context) async {
    try {
      // Track payment attempt
      await Sentry.captureMessage(
        'Monthly premium purchase initiated',
        level: SentryLevel.info,
        withScope: (scope) {
          scope.setTag('service', 'web_payment');
          scope.setTag('operation', 'purchase_monthly');
          scope.setTag('plan_type', 'monthly');
        },
      );

      // Open payment webview
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebView(
            paymentUrl: _monthlyPlanUrl,
            title: 'Monthly Premium - WhispTask',
            planType: 'monthly',
          ),
        ),
      );

      if (result == true) {
        // Payment successful, activate premium
        final prefs = await SharedPreferences.getInstance();
        DateTime expiryDate = DateTime.now().add(const Duration(days: 30));
        await prefs.setBool(_premiumKey, true);
        await prefs.setInt(_premiumExpiryKey, expiryDate.millisecondsSinceEpoch);
        
        print('Monthly premium activated until: $expiryDate');
        
        // Track successful payment
        await Sentry.captureMessage(
          'Monthly premium purchase completed successfully',
          level: SentryLevel.info,
          withScope: (scope) {
            scope.setTag('service', 'web_payment');
            scope.setTag('operation', 'purchase_success');
            scope.setTag('plan_type', 'monthly');
            scope.setExtra('expiry_date', expiryDate.toIso8601String());
          },
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Monthly purchase failed: $e');
      
      // Track payment failure
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('service', 'web_payment');
          scope.setTag('operation', 'purchase_monthly');
          scope.level = SentryLevel.error;
        },
      );
      
      return false;
    }
  }
  
  /// Open web payment for yearly premium
  static Future<bool> purchaseYearlyPremium(BuildContext context) async {
    try {
      // Track payment attempt
      await Sentry.captureMessage(
        'Yearly premium purchase initiated',
        level: SentryLevel.info,
        withScope: (scope) {
          scope.setTag('service', 'web_payment');
          scope.setTag('operation', 'purchase_yearly');
          scope.setTag('plan_type', 'yearly');
        },
      );

      // Open payment webview
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebView(
            paymentUrl: _yearlyPlanUrl,
            title: 'Yearly Premium - WhispTask',
            planType: 'yearly',
          ),
        ),
      );

      if (result == true) {
        // Payment successful, activate premium
        final prefs = await SharedPreferences.getInstance();
        DateTime expiryDate = DateTime.now().add(const Duration(days: 365));
        await prefs.setBool(_premiumKey, true);
        await prefs.setInt(_premiumExpiryKey, expiryDate.millisecondsSinceEpoch);
        
        print('Yearly premium activated until: $expiryDate');
        
        // Track successful payment
        await Sentry.captureMessage(
          'Yearly premium purchase completed successfully',
          level: SentryLevel.info,
          withScope: (scope) {
            scope.setTag('service', 'web_payment');
            scope.setTag('operation', 'purchase_success');
            scope.setTag('plan_type', 'yearly');
            scope.setExtra('expiry_date', expiryDate.toIso8601String());
          },
        );
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Yearly purchase failed: $e');
      
      // Track payment failure
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('service', 'web_payment');
          scope.setTag('operation', 'purchase_yearly');
          scope.level = SentryLevel.error;
        },
      );
      
      return false;
    }
  }
  
  static Future<void> restorePurchases() async {
    try {
      // For web payments, we just check current premium status
      bool isPremium = await isPremiumUser();
      print('Premium status restored (local): $isPremium');
      
      // Track restore attempt
      await Sentry.captureMessage(
        'Purchases restore completed',
        level: SentryLevel.info,
        withScope: (scope) {
          scope.setTag('service', 'web_payment');
          scope.setTag('operation', 'restore_purchases');
          scope.setExtra('is_premium', isPremium);
        },
      );
    } catch (e) {
      print('Failed to restore purchases: $e');
      
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('service', 'web_payment');
          scope.setTag('operation', 'restore_purchases');
          scope.level = SentryLevel.error;
        },
      );
    }
  }
  
  static Future<void> revokePremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, false);
      await prefs.remove(_premiumExpiryKey);
      print('Premium status revoked');
      
      // Track revocation
      await Sentry.captureMessage(
        'Premium status revoked',
        level: SentryLevel.info,
        withScope: (scope) {
          scope.setTag('service', 'web_payment');
          scope.setTag('operation', 'revoke_premium');
        },
      );
    } catch (e) {
      print('Failed to revoke premium: $e');
    }
  }
}

/// WebView widget for handling payments
class PaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final String title;
  final String planType;

  const PaymentWebView({
    super.key,
    required this.paymentUrl,
    required this.title,
    required this.planType,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }
  
  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'PaymentHandler',
        onMessageReceived: (JavaScriptMessage message) {
          final data = message.message;
          print('Payment result: $data');
          
          if (data.contains('success')) {
            Navigator.of(context).pop(true);
          } else if (data.contains('retry')) {
            // Reload the payment page for retry
            _loadPaymentPage();
          } else if (data.contains('free_trial')) {
            // Handle free trial activation
            _handleFreeTrial();
          } else if (data.contains('cancel')) {
            Navigator.of(context).pop(false);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading progress
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
            
            // Track webview errors
            Sentry.captureMessage(
              'Payment WebView error: ${error.description}',
              level: SentryLevel.error,
              withScope: (scope) {
                scope.setTag('service', 'web_payment');
                scope.setTag('operation', 'webview_error');
                scope.setTag('plan_type', widget.planType);
                scope.setExtra('error_code', error.errorCode);
                scope.setExtra('error_type', error.errorType.toString());
              },
            );
          },
        ),
      );
    
    // Load HTML content from assets
    _loadPaymentPage();
  }
  

  Future<void> _loadPaymentPage() async {
    try {
      // Use our enhanced embedded HTML directly
      print('🔄 Using enhanced embedded HTML with payment form');
      String htmlContent = _getEmbeddedPaymentHTML();
      
      // Inject JavaScript channel communication
      htmlContent = htmlContent.replaceAll(
        'if (window.flutter_inappwebview) {',
        'if (window.PaymentHandler) {'
      ).replaceAll(
        'window.flutter_inappwebview.callHandler',
        'window.PaymentHandler.postMessage'
      );
      
      // Inject plan type from URL parameters
      final planType = widget.planType.toLowerCase();
      htmlContent = htmlContent.replaceAll('{{PLAN_TYPE}}', planType);
      
      // Load HTML content directly
      print('📄 Loading HTML content (${htmlContent.length} characters)');
      print('🎯 Plan type: $planType');
      
      // Force reload with base URL and timestamp to ensure fresh content
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _controller.loadHtmlString(
        htmlContent,
        baseUrl: 'https://whisptask.local/?t=$timestamp',
      );
      print('✅ Payment page loaded successfully');
    } catch (e) {
      print('❌ Failed to load payment page: $e');
      
      // Fallback: Show error message
      const fallbackHtml = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Payment Error</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-align: center;
            padding: 20px;
          }
          .error-container {
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
          }
          h1 { margin-bottom: 20px; }
          button {
            background: rgba(255, 255, 255, 0.2);
            border: none;
            padding: 15px 30px;
            border-radius: 10px;
            color: white;
            font-size: 16px;
            cursor: pointer;
            margin-top: 20px;
          }
        </style>
      </head>
      <body>
        <div class="error-container">
          <h1>Payment Page Error</h1>
          <p>Unable to load payment page. Please try again later.</p>
          <button onclick="window.PaymentHandler.postMessage('cancel')">Return to App</button>
        </div>
      </body>
      </html>
      ''';
      
      await _controller.loadHtmlString(fallbackHtml);
    }
  }

  Future<void> _handleFreeTrial() async {
    try {
      // Activate 7-day free trial
      final prefs = await SharedPreferences.getInstance();
      DateTime expiryDate = DateTime.now().add(const Duration(days: 7));
      await prefs.setBool('is_free_trial_user', true);
      await prefs.setInt('free_trial_expiry_date', expiryDate.millisecondsSinceEpoch);
      
      print('Free trial activated until: $expiryDate');
      
      // Track free trial activation
      await Sentry.captureMessage(
        'Free trial activated',
        level: SentryLevel.info,
        withScope: (scope) {
          scope.setTag('service', 'web_payment');
          scope.setTag('operation', 'free_trial_activation');
          scope.setTag('plan_type', widget.planType);
          scope.setExtra('expiry_date', expiryDate.toIso8601String());
        },
      );
      
      // Return success to indicate trial was activated
      Navigator.of(context).pop(true);
    } catch (e) {
      print('Failed to activate free trial: $e');
      
      // Track free trial failure
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('service', 'web_payment');
          scope.setTag('operation', 'free_trial_activation');
          scope.level = SentryLevel.error;
        },
      );
      
      // Still return false to indicate failure
      Navigator.of(context).pop(false);
    }
  }

  String _getEmbeddedPaymentHTML() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WhispTask Premium - Payment</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 30%, #f093fb 70%, #667eea 100%);
            background-size: 400% 400%;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
            animation: gradientShift 12s ease-in-out infinite;
            overflow-x: hidden;
        }
        
        @keyframes gradientShift {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }
        
        .payment-container {
            background: rgba(255, 255, 255, 0.98);
            backdrop-filter: blur(30px);
            border-radius: 32px;
            padding: 60px 50px;
            box-shadow: 
                0 40px 80px rgba(0,0,0,0.15),
                0 0 0 1px rgba(255,255,255,0.2),
                inset 0 1px 0 rgba(255,255,255,0.3);
            max-width: 600px;
            width: 100%;
            text-align: center;
            position: relative;
            overflow: hidden;
            animation: slideUp 0.8s cubic-bezier(0.4, 0, 0.2, 1);
        }
        
        @keyframes slideUp {
            from { opacity: 0; transform: translateY(30px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .premium-badge {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: linear-gradient(135deg, #fbbf24, #f59e0b);
            color: white;
            padding: 8px 20px;
            border-radius: 25px;
            font-size: 0.9em;
            font-weight: 700;
            margin-bottom: 20px;
            box-shadow: 0 4px 15px rgba(251, 191, 36, 0.4);
            animation: badgePulse 2s ease-in-out infinite;
        }
        
        @keyframes badgePulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.05); }
        }
        
        .logo {
            font-size: 3.5em;
            font-weight: 900;
            background: linear-gradient(135deg, #667eea, #764ba2, #f093fb);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 12px;
            animation: logoFloat 3s ease-in-out infinite;
            text-shadow: 0 4px 20px rgba(102, 126, 234, 0.3);
        }
        
        @keyframes logoFloat {
            0%, 100% { transform: translateY(0px); }
            50% { transform: translateY(-5px); }
        }
        
        .subtitle {
            font-size: 1.2em;
            color: #64748b;
            font-weight: 500;
            margin-bottom: 40px;
            line-height: 1.6;
        }
        
        .plan-card {
            background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
            border-radius: 24px;
            padding: 40px;
            margin: 40px 0;
            border: 2px solid rgba(102, 126, 234, 0.1);
            position: relative;
            overflow: hidden;
        }
        
        .plan-price {
            font-size: 3.5em;
            font-weight: 900;
            background: linear-gradient(135deg, #667eea, #764ba2);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 8px;
        }
        
        .plan-name {
            font-size: 1.4em;
            font-weight: 700;
            color: #374151;
            margin-bottom: 24px;
        }
        
        .features-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin: 32px 0;
            text-align: left;
        }
        
        .feature-item {
            display: flex;
            align-items: center;
            padding: 16px;
            background: rgba(255, 255, 255, 0.8);
            border-radius: 16px;
            transition: all 0.3s ease;
            border: 1px solid rgba(102, 126, 234, 0.1);
        }
        
        .feature-item:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(102, 126, 234, 0.15);
        }
        
        .feature-icon {
            color: #667eea;
            font-size: 1.3em;
            margin-right: 12px;
            min-width: 20px;
        }
        
        .feature-text {
            font-size: 0.95em;
            font-weight: 600;
            color: #374151;
        }
        
        .payment-buttons {
            display: flex;
            flex-direction: column;
            gap: 16px;
            margin-top: 40px;
        }
        
        .btn {
            padding: 18px 36px;
            border: none;
            border-radius: 16px;
            font-size: 1.1em;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
            position: relative;
            overflow: hidden;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            box-shadow: 0 8px 32px rgba(102, 126, 234, 0.3);
        }
        
        .btn-primary:hover {
            transform: translateY(-3px);
            box-shadow: 0 16px 48px rgba(102, 126, 234, 0.4);
        }
        
        .btn-secondary {
            background: rgba(255, 255, 255, 0.9);
            color: #64748b;
            border: 2px solid rgba(102, 126, 234, 0.2);
        }
        
        .btn-secondary:hover {
            background: rgba(102, 126, 234, 0.1);
            border-color: rgba(102, 126, 234, 0.4);
            transform: translateY(-2px);
        }
        
        /* Payment Modal Styles */
        .payment-modal {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.8);
            backdrop-filter: blur(10px);
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 1000;
            animation: fadeIn 0.3s ease;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        .payment-form-container {
            background: white;
            border-radius: 20px;
            padding: 30px;
            max-width: 500px;
            width: 90%;
            max-height: 80vh;
            overflow-y: auto;
            animation: slideUp 0.3s ease;
        }
        
        @keyframes slideUp {
            from { transform: translateY(50px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }
        
        .payment-form-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid #f0f0f0;
        }
        
        .payment-form-header h3 {
            margin: 0;
            color: #333;
            font-size: 1.5em;
        }
        
        .close-btn {
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: #999;
            padding: 5px;
            border-radius: 50%;
            width: 35px;
            height: 35px;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .close-btn:hover {
            background: #f0f0f0;
            color: #333;
        }
        
        .payment-tabs {
            display: flex;
            margin-bottom: 25px;
            border-bottom: 1px solid #e0e0e0;
        }
        
        .tab-btn {
            flex: 1;
            padding: 12px 8px;
            border: none;
            background: none;
            cursor: pointer;
            font-size: 14px;
            color: #666;
            border-bottom: 2px solid transparent;
            transition: all 0.3s ease;
        }
        
        .tab-btn.active {
            color: #667eea;
            border-bottom-color: #667eea;
        }
        
        .tab-btn:hover {
            color: #667eea;
            background: rgba(102, 126, 234, 0.05);
        }
        
        .payment-form-content {
            margin-bottom: 25px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
            font-size: 14px;
        }
        
        .form-group input,
        .form-group select {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid #e0e0e0;
            border-radius: 10px;
            font-size: 16px;
            transition: border-color 0.3s ease;
            box-sizing: border-box;
        }
        
        .form-group input:focus,
        .form-group select:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        .form-row {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 15px;
        }
        
        .card-icons {
            display: flex;
            gap: 10px;
            margin-top: 10px;
        }
        
        .card-icons i {
            font-size: 24px;
            color: #666;
        }
        
        .upi-icons {
            display: flex;
            align-items: center;
            gap: 15px;
            margin-top: 10px;
            flex-wrap: wrap;
        }
        
        .upi-icons img {
            width: 30px;
            height: 30px;
        }
        
        .upi-icons span {
            background: #f0f0f0;
            padding: 5px 10px;
            border-radius: 15px;
            font-size: 12px;
            color: #666;
        }
        
        .qr-section {
            text-align: center;
            margin-top: 20px;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 10px;
        }
        
        .qr-placeholder {
            width: 150px;
            height: 150px;
            background: white;
            border: 2px dashed #ddd;
            border-radius: 10px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            margin: 15px auto;
        }
        
        .qr-placeholder i {
            font-size: 48px;
            color: #999;
            margin-bottom: 10px;
        }
        
        .payment-summary {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
        }
        
        .summary-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            font-size: 14px;
        }
        
        .summary-row.total {
            font-weight: bold;
            font-size: 16px;
            padding-top: 10px;
            border-top: 1px solid #ddd;
            margin-top: 10px;
        }
        
        .payment-btn {
            width: 100%;
            padding: 15px;
            font-size: 16px;
            font-weight: bold;
        }
        
        @media (max-width: 768px) {
            .payment-container {
                padding: 40px 30px;
                margin: 10px;
            }
            
            .features-grid {
                grid-template-columns: 1fr;
            }
            
            .logo {
                font-size: 2.8em;
            }
            
            .plan-price {
                font-size: 2.8em;
            }
            
            .payment-form-container {
                margin: 20px;
                padding: 20px;
            }
            
            .form-row {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="payment-container">
        <div class="premium-badge">
            <i class="fas fa-crown"></i>
            <span>Premium Upgrade</span>
        </div>
        
        <div class="logo">
            <span style="margin-right: 12px;">🎤</span>WhispTask
        </div>
        
        <div class="subtitle">Unlock Premium Features & Supercharge Your Productivity</div>
        
        <div class="plan-card">
            <div class="plan-price" id="planPrice">₹149</div>
            <div class="plan-name" id="planName">Monthly Premium</div>
            <div class="plan-savings" id="planSavings" style="display: none;">Save ₹589 yearly!</div>
            
            <div class="features-grid">
                <div class="feature-item">
                    <i class="fas fa-microphone feature-icon"></i>
                    <span class="feature-text">Unlimited Voice Commands</span>
                </div>
                <div class="feature-item">
                    <i class="fas fa-chart-line feature-icon"></i>
                    <span class="feature-text">Advanced Analytics</span>
                </div>
                <div class="feature-item">
                    <i class="fas fa-cloud-sync feature-icon"></i>
                    <span class="feature-text">Cloud Synchronization</span>
                </div>
                <div class="feature-item">
                    <i class="fas fa-headset feature-icon"></i>
                    <span class="feature-text">Priority Support</span>
                </div>
            </div>
        </div>
        
        <div class="payment-buttons">
            <button class="btn btn-primary" id="subscribeBtn" onclick="showPaymentForm()">
                <i class="fas fa-credit-card" style="margin-right: 8px;"></i>
                <span id="subscribeText">Subscribe Now - ₹149/month</span>
            </button>
            <button class="btn btn-secondary" onclick="cancelPayment()">
                <i class="fas fa-times" style="margin-right: 8px;"></i>
                Maybe Later
            </button>
        </div>
        
        <!-- Payment Form Modal -->
        <div id="paymentModal" class="payment-modal" style="display: none;">
            <div class="payment-form-container">
                <div class="payment-form-header">
                    <h3>Complete Your Payment</h3>
                    <button class="close-btn" onclick="hidePaymentForm()">×</button>
                </div>
                
                <div class="payment-tabs">
                    <button class="tab-btn active" onclick="switchTab('card')">
                        <i class="fas fa-credit-card"></i> Card
                    </button>
                    <button class="tab-btn" onclick="switchTab('upi')">
                        <i class="fas fa-mobile-alt"></i> UPI
                    </button>
                    <button class="tab-btn" onclick="switchTab('netbanking')">
                        <i class="fas fa-university"></i> Net Banking
                    </button>
                </div>
                
                <!-- Card Payment Form -->
                <div id="cardForm" class="payment-form-content">
                    <div class="form-group">
                        <label>Card Number</label>
                        <input type="text" id="cardNumber" placeholder="1234 5678 9012 3456" maxlength="19">
                        <div class="card-icons">
                            <i class="fab fa-cc-visa"></i>
                            <i class="fab fa-cc-mastercard"></i>
                            <i class="fab fa-cc-amex"></i>
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Expiry Date</label>
                            <input type="text" id="expiryDate" placeholder="MM/YY" maxlength="5">
                        </div>
                        <div class="form-group">
                            <label>CVV</label>
                            <input type="text" id="cvv" placeholder="123" maxlength="4">
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Cardholder Name</label>
                        <input type="text" id="cardholderName" placeholder="John Doe">
                    </div>
                </div>
                
                <!-- UPI Payment Form -->
                <div id="upiForm" class="payment-form-content" style="display: none;">
                    <div class="form-group">
                        <label>UPI ID</label>
                        <input type="text" id="upiId" placeholder="yourname@paytm">
                        <div class="upi-icons">
                            <img src="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHZpZXdCb3g9IjAgMCA0MCA0MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHJlY3Qgd2lkdGg9IjQwIiBoZWlnaHQ9IjQwIiByeD0iOCIgZmlsbD0iIzAwNzlGRiIvPgo8cGF0aCBkPSJNMTIgMTJIMjhWMjhIMTJWMTJaIiBmaWxsPSJ3aGl0ZSIvPgo8L3N2Zz4K" alt="UPI">
                            <span>Google Pay</span>
                            <span>PhonePe</span>
                            <span>Paytm</span>
                        </div>
                    </div>
                    <div class="qr-section">
                        <p>Or scan QR code with any UPI app</p>
                        <div class="qr-placeholder">
                            <i class="fas fa-qrcode"></i>
                            <p>QR Code</p>
                        </div>
                    </div>
                </div>
                
                <!-- Net Banking Form -->
                <div id="netbankingForm" class="payment-form-content" style="display: none;">
                    <div class="form-group">
                        <label>Select Your Bank</label>
                        <select id="bankSelect">
                            <option value="">Choose your bank</option>
                            <option value="sbi">State Bank of India</option>
                            <option value="hdfc">HDFC Bank</option>
                            <option value="icici">ICICI Bank</option>
                            <option value="axis">Axis Bank</option>
                            <option value="kotak">Kotak Mahindra Bank</option>
                            <option value="pnb">Punjab National Bank</option>
                            <option value="other">Other Banks</option>
                        </select>
                    </div>
                </div>
                
                <div class="payment-summary">
                    <div class="summary-row">
                        <span>Plan:</span>
                        <span id="summaryPlan">Monthly Premium</span>
                    </div>
                    <div class="summary-row">
                        <span>Amount:</span>
                        <span id="summaryAmount">₹149</span>
                    </div>
                    <div class="summary-row total">
                        <span>Total:</span>
                        <span id="summaryTotal">₹149</span>
                    </div>
                </div>
                
                <button class="btn btn-primary payment-btn" onclick="processPayment()">
                    <i class="fas fa-lock" style="margin-right: 8px;"></i>
                    Pay Securely
                </button>
            </div>
        </div>
    </div>

    <script>
        // Get plan type from URL or default to monthly
        const urlParams = new URLSearchParams(window.location.search);
        const planType = urlParams.get('plan') || '{{PLAN_TYPE}}' || 'monthly';
        
        // Initialize page with correct plan
        document.addEventListener('DOMContentLoaded', function() {
            updatePlanDisplay(planType);
            setupFormValidation();
        });
        
        function updatePlanDisplay(plan) {
            const planPrice = document.getElementById('planPrice');
            const planName = document.getElementById('planName');
            const planSavings = document.getElementById('planSavings');
            const subscribeText = document.getElementById('subscribeText');
            const summaryPlan = document.getElementById('summaryPlan');
            const summaryAmount = document.getElementById('summaryAmount');
            const summaryTotal = document.getElementById('summaryTotal');
            
            if (plan === 'yearly') {
                planPrice.textContent = '₹1,199';
                planName.textContent = 'Yearly Premium';
                planSavings.style.display = 'block';
                planSavings.textContent = 'Save ₹589 yearly!';
                subscribeText.textContent = 'Subscribe Now - ₹1,199/year';
                summaryPlan.textContent = 'Yearly Premium';
                summaryAmount.textContent = '₹1,199';
                summaryTotal.textContent = '₹1,199';
            } else {
                planPrice.textContent = '₹149';
                planName.textContent = 'Monthly Premium';
                planSavings.style.display = 'none';
                subscribeText.textContent = 'Subscribe Now - ₹149/month';
                summaryPlan.textContent = 'Monthly Premium';
                summaryAmount.textContent = '₹149';
                summaryTotal.textContent = '₹149';
            }
        }
        
        function showPaymentForm() {
            document.getElementById('paymentModal').style.display = 'flex';
            document.body.style.overflow = 'hidden';
        }
        
        function hidePaymentForm() {
            document.getElementById('paymentModal').style.display = 'none';
            document.body.style.overflow = 'auto';
        }
        
        function switchTab(tabName) {
            // Hide all forms
            document.getElementById('cardForm').style.display = 'none';
            document.getElementById('upiForm').style.display = 'none';
            document.getElementById('netbankingForm').style.display = 'none';
            
            // Remove active class from all tabs
            document.querySelectorAll('.tab-btn').forEach(btn => {
                btn.classList.remove('active');
            });
            
            // Show selected form and activate tab
            document.getElementById(tabName + 'Form').style.display = 'block';
            event.target.classList.add('active');
        }
        
        function setupFormValidation() {
            // Card number formatting
            const cardNumber = document.getElementById('cardNumber');
            cardNumber.addEventListener('input', function(e) {
                let value = e.target.value.replace(/ /g, '').replace(/[^0-9]/gi, '');
                let formattedValue = value.match(/.{1,4}/g)?.join(' ') || value;
                e.target.value = formattedValue;
            });
            
            // Expiry date formatting
            const expiryDate = document.getElementById('expiryDate');
            expiryDate.addEventListener('input', function(e) {
                let value = e.target.value.replace(/[^0-9]/g, '');
                if (value.length >= 2) {
                    value = value.substring(0, 2) + '/' + value.substring(2, 4);
                }
                e.target.value = value;
            });
            
            // CVV validation
            const cvv = document.getElementById('cvv');
            cvv.addEventListener('input', function(e) {
                e.target.value = e.target.value.replace(/[^0-9]/g, '');
            });
            
            // UPI ID validation
            const upiId = document.getElementById('upiId');
            upiId.addEventListener('input', function(e) {
                const value = e.target.value.toLowerCase();
                if (value.includes('@')) {
                    e.target.style.borderColor = '#10b981';
                } else {
                    e.target.style.borderColor = '#e0e0e0';
                }
            });
        }
        
        function validateForm() {
            const activeTab = document.querySelector('.tab-btn.active').textContent.trim();
            
            if (activeTab.includes('Card')) {
                const cardNumber = document.getElementById('cardNumber').value.replace(/ /g, '');
                const expiryDate = document.getElementById('expiryDate').value;
                const cvv = document.getElementById('cvv').value;
                const cardholderName = document.getElementById('cardholderName').value;
                
                if (cardNumber.length < 13 || cardNumber.length > 19) {
                    alert('Please enter a valid card number');
                    return false;
                }
                if (expiryDate.length !== 5 || !expiryDate.includes('/')) {
                    alert('Please enter a valid expiry date (MM/YY)');
                    return false;
                }
                if (cvv.length < 3 || cvv.length > 4) {
                    alert('Please enter a valid CVV');
                    return false;
                }
                if (cardholderName.trim().length < 2) {
                    alert('Please enter the cardholder name');
                    return false;
                }
            } else if (activeTab.includes('UPI')) {
                const upiId = document.getElementById('upiId').value;
                if (!upiId.includes('@') || upiId.length < 5) {
                    alert('Please enter a valid UPI ID');
                    return false;
                }
            } else if (activeTab.includes('Net Banking')) {
                const bank = document.getElementById('bankSelect').value;
                if (!bank) {
                    alert('Please select your bank');
                    return false;
                }
            }
            
            return true;
        }
        
        function processPayment() {
            if (!validateForm()) {
                return;
            }
            
            const btn = event.target;
            const originalText = btn.innerHTML;
            btn.innerHTML = '<i class="fas fa-spinner fa-spin" style="margin-right: 8px;"></i>Processing Payment...';
            btn.disabled = true;
            
            // Simulate payment processing with realistic delay
            setTimeout(() => {
                // Add success animation
                btn.innerHTML = '<i class="fas fa-check" style="margin-right: 8px;"></i>Payment Successful!';
                btn.style.background = 'linear-gradient(135deg, #10b981, #059669)';
                
                setTimeout(() => {
                    if (window.PaymentHandler) {
                        window.PaymentHandler.postMessage('success');
                    } else {
                        alert('Payment successful! Returning to app...');
                        hidePaymentForm();
                    }
                }, 1000);
            }, 3000);
        }
        
        function cancelPayment() {
            if (window.PaymentHandler) {
                window.PaymentHandler.postMessage('cancel');
            } else {
                alert('Payment cancelled');
            }
        }
        
        // Close modal when clicking outside
        document.addEventListener('click', function(e) {
            const modal = document.getElementById('paymentModal');
            if (e.target === modal) {
                hidePaymentForm();
            }
        });
        
        // Add keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                const modal = document.getElementById('paymentModal');
                if (modal.style.display === 'flex') {
                    hidePaymentForm();
                } else {
                    cancelPayment();
                }
            }
        });
    </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1976D2), // Blue header matching app theme
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(false),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1976D2).withOpacity(0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
