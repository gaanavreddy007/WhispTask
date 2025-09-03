// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class AdService {
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    print('Local ad service initialized (no external ads)');
  }
  
  static Widget? getBannerAdWidget(BuildContext context) {
    // Return a visible banner ad for free users
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[100]!, Colors.blue[200]!],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context).sampleAdBanner,
              style: TextStyle(
                color: Colors.blue[800],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              AppLocalizations.of(context).upgradeToRemoveAds,
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  static void disposeBannerAd() {
    // No-op for local system
  }
  
  static bool get isAdLoaded => true; // Always show placeholder
}
