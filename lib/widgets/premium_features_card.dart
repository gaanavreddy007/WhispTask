// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/premium_purchase_screen.dart';

class PremiumFeaturesCard extends StatelessWidget {
  const PremiumFeaturesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).premiumFeatures,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• ${AppLocalizations.of(context).customVoicePacks}\n• ${AppLocalizations.of(context).offlineMode}\n• ${AppLocalizations.of(context).smartTags}\n• ${AppLocalizations.of(context).customThemes}\n• ${AppLocalizations.of(context).advancedAnalytics}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PremiumPurchaseScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.upgrade, size: 18),
                label: Text(AppLocalizations.of(context).upgradeToProLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
