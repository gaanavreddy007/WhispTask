// ignore_for_file: deprecated_member_use, use_build_context_synchronously, prefer_const_constructors, unused_element, avoid_print, unused_import

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import 'language_settings_screen.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_strength_indicator.dart';
import '../utils/validators.dart';
import '../utils/premium_helper.dart';
import '../models/sync_status.dart';
import '../models/user_model.dart' hide ThemeMode;
import '../l10n/app_localizations.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).accountSettings),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        actions: [
          // Sync Status Indicator
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return StreamBuilder<SyncStatus>(
                stream: authProvider.syncStatusStream,
                builder: (context, snapshot) {
                  final status = snapshot.data ?? SyncStatus.idle;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: _getSyncIcon(status),
                      onPressed: status == SyncStatus.syncing ? null : () => authProvider.forceSyncUserData(),
                      tooltip: _getSyncTooltip(status),
                    ),
                  );
                },
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1976D2),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF1976D2),
          tabs: [
            Tab(text: AppLocalizations.of(context).security),
            Tab(text: AppLocalizations.of(context).privacy),
            Tab(text: AppLocalizations.of(context).account),
          ],
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _SecurityTab(authProvider: authProvider),
              _PrivacyTab(authProvider: authProvider),
              _AccountTab(authProvider: authProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _getSyncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
          ),
        );
      case SyncStatus.success:
        return const Icon(Icons.cloud_done, color: Colors.green);
      case SyncStatus.error:
        return const Icon(Icons.cloud_off, color: Colors.red);
      case SyncStatus.offline:
        return const Icon(Icons.cloud_queue, color: Colors.orange);
      default:
        return const Icon(Icons.cloud, color: Colors.grey);
    }
  }

  String _getSyncTooltip(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return AppLocalizations.of(context).syncing;
      case SyncStatus.success:
        return AppLocalizations.of(context).synced;
      case SyncStatus.error:
        return AppLocalizations.of(context).syncError;
      case SyncStatus.offline:
        return AppLocalizations.of(context).offline;
      default:
        return AppLocalizations.of(context).tapToSync;
    }
  }
}

class _PrivacyTab extends StatefulWidget {
  final AuthProvider authProvider;
  
  const _PrivacyTab({required this.authProvider});

  @override
  State<_PrivacyTab> createState() => _PrivacyTabState();
}

class _PrivacyTabState extends State<_PrivacyTab> {
  bool _biometricAuthEnabled = false;
  bool _analyticsEnabled = true;
  bool _crashReportsEnabled = true;
  bool _marketingEmails = false;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final user = widget.authProvider.user;
    if (user != null) {
      setState(() {
        _biometricAuthEnabled = user.privacySettings?.biometricAuth ?? false;
        _analyticsEnabled = user.privacySettings?.shareAnalytics ?? true;
        _crashReportsEnabled = user.privacySettings?.shareCrashReports ?? true;
        _marketingEmails = user.privacySettings?.marketingEmails ?? false;
        _pushNotifications = user.preferences.notificationsEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildSecurityPreferencesCard(),
          const SizedBox(height: 24),
          _buildDataPrivacyCard(),
          const SizedBox(height: 24),
          _buildNotificationPreferencesCard(),
          const SizedBox(height: 24),
          _buildLanguagePreferencesCard(),
          const SizedBox(height: 24),
          _buildDataManagementCard(),
        ],
      ),
    );
  }

  Widget _buildSecurityPreferencesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.security, color: Colors.blue[700], size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Security Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildPrivacyOption(
            'Biometric Authentication',
            'Use fingerprint or face recognition to unlock the app',
            Icons.fingerprint,
            _biometricAuthEnabled,
            (value) async {
              try {
                await widget.authProvider.updatePrivacySettings(biometricAuth: value);
                setState(() => _biometricAuthEnabled = value);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value 
                      ? 'Biometric authentication enabled!' 
                      : 'Biometric authentication disabled'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update biometric settings: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataPrivacyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.privacy_tip, color: Colors.purple[700], size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Data Privacy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildPrivacyOption(
            'Analytics Data',
            'Help improve the app by sharing usage analytics',
            Icons.analytics_outlined,
            _analyticsEnabled,
            (value) async {
              try {
                await widget.authProvider.updatePrivacySettings(enableAnalytics: value);
                setState(() => _analyticsEnabled = value);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update analytics settings: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          
          _buildPrivacyOption(
            'Crash Reports',
            'Automatically send crash reports to help fix issues',
            Icons.bug_report_outlined,
            _crashReportsEnabled,
            (value) async {
              try {
                await widget.authProvider.updatePrivacySettings(shareUsageData: value);
                setState(() => _crashReportsEnabled = value);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update crash report settings: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          
          _buildPrivacyOption(
            'Marketing Emails',
            'Receive tips, updates, and promotional content',
            Icons.email_outlined,
            _marketingEmails,
            (value) async {
              try {
                await widget.authProvider.updatePrivacySettings(biometricAuth: value);
                setState(() => _marketingEmails = value);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update email settings: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPreferencesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.notifications_outlined, color: Colors.blue[700], size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildPrivacyOption(
            'Push Notifications',
            'Receive task reminders and app updates',
            Icons.push_pin_outlined,
            _pushNotifications,
            (value) async {
              try {
                final currentPrefs = widget.authProvider.userPreferences ?? UserPreferences.defaultPreferences();
                final updatedPrefs = currentPrefs.copyWith(notificationsEnabled: value);
                await widget.authProvider.updateUserPreferences(updatedPrefs);
                setState(() => _pushNotifications = value);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update notification settings: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.storage, color: Colors.orange[700], size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Data Management',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildActionButton(
            'Export Data',
            'Download a copy of your tasks and account data',
            Icons.download_outlined,
            Colors.blue,
            _exportData,
          ),
          const SizedBox(height: 12),
          
          _buildActionButton(
            'Import Data',
            'Restore data from a previous export',
            Icons.upload_outlined,
            Colors.green,
            _importData,
          ),
          const SizedBox(height: 12),
          
          _buildActionButton(
            'Clear Cache',
            'Clear locally stored app data and preferences',
            Icons.clear_all,
            Colors.orange,
            _clearCache,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Future<void> Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) async {
              await onChanged(newValue);
            },
            activeColor: const Color(0xFF1976D2),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _exportData() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting data...'),
            ],
          ),
        ),
      );

      // Use the actual export function
      final result = await widget.authProvider.exportUserData();
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (result != null) {
        // Show success with options to share or copy
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Export Complete'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your data has been exported successfully!'),
                const SizedBox(height: 16),
                Text(
                  'File size: ${(jsonEncode(result).length / 1024).toStringAsFixed(1)} KB',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: jsonEncode(result)));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export data copied to clipboard!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Copy to Clipboard'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _importData() async {
    // Show import options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.upload, color: Colors.green),
            SizedBox(width: 8),
            Text('Import Data'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose how to import your data:'),
            SizedBox(height: 16),
            Text(
              'Note: This will merge with your existing data. Duplicate tasks will be skipped.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _importFromClipboard();
            },
            child: const Text('From Clipboard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _importFromFile();
            },
            child: const Text('From File'),
          ),
        ],
      ),
    );
  }

  void _importFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData?.text == null || clipboardData!.text!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No data found in clipboard'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await _performImport(clipboardData.text!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import from clipboard failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _importFromFile() async {
    // For now, show a placeholder since file picker would need additional setup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File picker integration coming soon! Use clipboard import for now.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _performImport(String data) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Importing data...'),
            ],
          ),
        ),
      );

      // Parse JSON data and use the actual import function
      final Map<String, dynamic> importData = jsonDecode(data);
      final success = await widget.authProvider.importUserData(importData);
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data imported successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import failed: Invalid data format'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildLanguagePreferencesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.language, color: Colors.green[700], size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Language Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildActionButton(
            'App Language',
            'Change the language of the app interface',
            Icons.translate,
            Colors.green,
            () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LanguageSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear locally stored data and preferences. Your account data will remain safe in the cloud. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Clearing cache...'),
                      ],
                    ),
                  ),
                );

                // Use the actual clear cache function
                await widget.authProvider.clearUserCache();
                
                Navigator.of(context).pop(); // Close loading dialog
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // Reload settings from server
                _loadCurrentSettings();
              } catch (e) {
                Navigator.of(context).pop(); // Close loading dialog if open
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to clear cache: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _AccountTab extends StatefulWidget {
  final AuthProvider authProvider;
  
  const _AccountTab({required this.authProvider});

  @override
  State<_AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<_AccountTab> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.authProvider.user!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildPremiumStatusCard(),
          const SizedBox(height: 24),
          _buildAccountInfoCard(user),
          const SizedBox(height: 24),
          _buildSyncStatusCard(),
          const SizedBox(height: 24),
          _buildAccountActionsCard(user),
          const SizedBox(height: 24),
          _buildDangerZoneCard(user),
        ],
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.sync, color: Colors.blue[700], size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Sync Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          StreamBuilder<SyncStatus>(
            stream: widget.authProvider.syncStatusStream,
            builder: (context, snapshot) {
              final status = snapshot.data ?? SyncStatus.idle;
              final statusInfo = _getSyncStatusInfo(status);
              
              return Column(
                children: [
                  Row(
                    children: [
                      Icon(statusInfo['icon'], color: statusInfo['color'], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusInfo['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              statusInfo['subtitle'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (status != SyncStatus.syncing)
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => widget.authProvider.forceSyncUserData(),
                          tooltip: 'Force sync',
                        ),
                    ],
                  ),
                  if (status == SyncStatus.syncing) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getSyncStatusInfo(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return {
          'icon': Icons.sync,
          'color': Colors.blue,
          'title': 'Syncing...',
          'subtitle': 'Updating your data across devices',
        };
      case SyncStatus.success:
        return {
          'icon': Icons.cloud_done,
          'color': Colors.green,
          'title': 'Synced',
          'subtitle': 'All data is up to date',
        };
      case SyncStatus.error:
        return {
          'icon': Icons.error_outline,
          'color': Colors.red,
          'title': 'Sync Error',
          'subtitle': 'Failed to sync data - tap refresh to retry',
        };
      case SyncStatus.offline:
        return {
          'icon': Icons.cloud_off,
          'color': Colors.orange,
          'title': 'Offline',
          'subtitle': 'Will sync when connection is restored',
        };
      default:
        return {
          'icon': Icons.cloud,
          'color': Colors.grey,
          'title': 'Ready to Sync',
          'subtitle': 'Tap refresh to sync your data',
        };
    }
  }

  Widget _buildPremiumStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: widget.authProvider.isPremium
            ? LinearGradient(
                colors: [Colors.amber.shade100, Colors.amber.shade50],
              )
            : LinearGradient(
                colors: [Colors.grey.shade100, Colors.grey.shade50],
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.authProvider.isPremium ? Colors.amber : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.authProvider.isPremium ? Icons.star : Icons.star_outline,
                color: widget.authProvider.isPremium ? Colors.amber : Colors.grey,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                widget.authProvider.isPremium ? 'Premium User' : 'Upgrade to Pro',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.authProvider.isPremium ? Colors.amber.shade700 : Colors.grey.shade700,
                ),
              ),
              if (widget.authProvider.isPremium) ...[
                const Spacer(),
                PremiumHelper.buildPremiumBadge(),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.authProvider.isPremium 
                ? 'Enjoying all premium features' 
                : 'Unlock unlimited tasks, custom voices, and no ads',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          if (!widget.authProvider.isPremium) ...[
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Features:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                _buildFeatureItem('Unlimited tasks per day'),
                _buildFeatureItem('Custom voice packs'),
                _buildFeatureItem('No advertisements'),
                _buildFeatureItem('Priority support'),
                _buildFeatureItem('Advanced analytics'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.authProvider.isLoading ? null : () {
                      Navigator.pushNamed(context, '/premium-purchase');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: widget.authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Upgrade to Pro - \$2.99/month',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () async {
                  try {
                    await widget.authProvider.restorePurchases();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Purchases restored successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Restore failed: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Restore Purchases'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeSelector(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.palette, color: Colors.indigo[700], size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'App Theme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  'System',
                  Icons.brightness_auto,
                  ThemeMode.system,
                  themeProvider.themeMode == ThemeMode.system,
                  () => themeProvider.setThemeMode(ThemeMode.system),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  'Light',
                  Icons.brightness_high,
                  ThemeMode.light,
                  themeProvider.themeMode == ThemeMode.light,
                  () => themeProvider.setThemeMode(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  'Dark',
                  Icons.brightness_2,
                  ThemeMode.dark,
                  themeProvider.themeMode == ThemeMode.dark,
                  () => themeProvider.setThemeMode(ThemeMode.dark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String label, IconData icon, ThemeMode mode, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1976D2) : Colors.grey[300]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          Text(
            feature,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoCard(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.account_circle, color: Colors.green[700], size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildInfoRow('User ID', user.uid.substring(0, 8) + '...'),
          _buildInfoRow('Account Type', user.accountType),
          if (user.email?.isNotEmpty ?? false)
            _buildInfoRow('Email', user.email!),
          _buildInfoRow('Member Since', user.memberSince),
          _buildInfoRow('Total Tasks', user.taskCount.toString()),
          _buildInfoRow('Completed Tasks', user.completedTaskCount.toString()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActionsCard(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          if (user.isAnonymous)
            _buildActionButton(
              'Upgrade to Full Account',
              'Create a permanent account with email/password',
              Icons.upgrade_outlined,
              Colors.green,
              () => Navigator.pushNamed(context, '/signup', arguments: true),
            )
          else
            _buildActionButton(
              'Download Account Data',
              'Export all your account data and tasks',
              Icons.download_outlined,
              Colors.blue,
              _downloadAccountData,
            ),
          
          const SizedBox(height: 12),
          
          _buildActionButton(
            'Contact Support',
            'Get help with your account or report issues',
            Icons.support_agent_outlined,
            Colors.purple,
            _contactSupport,
          ),
          
          const SizedBox(height: 12),
          
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _buildThemeSelector(themeProvider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning, color: Colors.red[700], size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildDangerButton(
            'Delete All Tasks',
            'Permanently delete all your tasks (account will remain)',
            Icons.delete_outline,
            _deleteAllTasks,
          ),
          const SizedBox(height: 12),
          
          _buildDangerButton(
            'Delete Account',
            'Permanently delete your account and all associated data',
            Icons.delete_forever,
            _deleteAccount,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Test Crash',
            'Trigger a test error to verify Sentry integration',
            Icons.bug_report,
            Colors.orange,
            () async {
              try {
                print('=== MANUAL SENTRY TEST ===');
                
                // Set user context
                Sentry.configureScope((scope) {
                  scope.setTag('test_type', 'manual_button_test');
                  scope.setUser(SentryUser(
                    id: 'test_user',
                    email: 'test@whispTask.com',
                  ));
                });
                
                // Test message
                final messageId = await Sentry.captureMessage(
                  'WhispTask manual test message - ${DateTime.now()}',
                  level: SentryLevel.info,
                );
                print('Captured message ID: $messageId');
                
                // Test exception
                final exceptionId = await Sentry.captureException(
                  Exception('Test exception from WhispTask'),
                  stackTrace: StackTrace.current,
                );
                print('Captured exception ID: $exceptionId');
                
                // Wait a moment for events to be queued
                await Future.delayed(Duration(seconds: 2));
                print('Events queued - should be sending to Sentry now');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sentry test completed - Check logs for event IDs'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                print('Sentry test failed: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sentry test failed: $e'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[100]?.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.red[700], size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.red[400],
            ),
          ],
        ),
      ),
    );
  }

  void _downloadAccountData() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Preparing download...'),
            ],
          ),
        ),
      );

      // Use the actual export function
      final result = await widget.authProvider.exportUserData();
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (result != null) {
        // Show success with options to share or copy
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Export Complete'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your account data has been exported successfully!'),
                const SizedBox(height: 16),
                Text(
                  'File size: ${(jsonEncode(result).length / 1024).toStringAsFixed(1)} KB',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: jsonEncode(result)));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export data copied to clipboard!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Copy to Clipboard'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Need help? Choose how you\'d like to contact us:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email Support'),
              subtitle: const Text('support@whispTask.com'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Live Chat'),
              subtitle: const Text('Available 9 AM - 5 PM'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _deleteAllTasks() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete All Tasks',
          style: TextStyle(color: Colors.red[700]),
        ),
        content: const Text(
          'This will permanently delete all your tasks. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final taskProvider = Provider.of<TaskProvider>(context, listen: false);
              final success = await taskProvider.deleteAllUserTasks();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'All tasks deleted!' : 'Failed to delete tasks'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Account',
          style: TextStyle(color: Colors.red[700]),
        ),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone. Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showDeleteAccountConfirmation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Confirm Account Deletion',
          style: TextStyle(color: Colors.red[700]),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your password to confirm account deletion:',
            ),
            const SizedBox(height: 16),
            if (!widget.authProvider.user!.isAnonymous)
              AuthTextField(
                controller: passwordController,
                label: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                validator: Validators.validatePassword,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isDeleting ? null : () => _confirmDeleteAccount(passwordController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: _isDeleting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('DELETE FOREVER'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(String password) async {
    setState(() => _isDeleting = true);

    final success = await widget.authProvider.deleteAccount(
      password: widget.authProvider.user!.isAnonymous ? null : password,
    );

    if (mounted) {
      setState(() => _isDeleting = false);
      Navigator.of(context).pop(); // Close dialog

      if (success) {
        // Account deleted, user will be redirected by auth state changes
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.authProvider.errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SecurityTab extends StatefulWidget {
  final AuthProvider authProvider;
  
  const _SecurityTab({required this.authProvider});

  @override
  State<_SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<_SecurityTab> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authProvider.user;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Account Status Card
          _buildStatusCard(user),
          const SizedBox(height: 24),
          
          // Change Password Section
          if (!user!.isAnonymous) _buildChangePasswordCard(),
          
          const SizedBox(height: 24),
          
          // Two-Factor Authentication (Future Enhancement)
          _buildSecurityOptionsCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard(user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: user.isAnonymous ? Colors.orange[100] : Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  user.isAnonymous ? Icons.warning_amber : Icons.verified_user,
                  color: user.isAnonymous ? Colors.orange[700] : Colors.green[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Account Security',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildSecurityItem(
            'Account Type',
            user.accountType,
            user.isAnonymous ? Icons.warning_amber : Icons.check_circle,
            user.isAnonymous ? Colors.orange : Colors.green,
          ),
          
          if (!user.isAnonymous) ...[
            const SizedBox(height: 12),
            _buildSecurityItem(
              'Email Verified',
              'Verified',
              Icons.verified,
              Colors.green,
            ),
          ],
          
          const SizedBox(height: 12),
          _buildSecurityItem(
            'Last Sign In',
            user.formattedLastSignIn,
            Icons.schedule,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildChangePasswordCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Password',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            
            AuthTextField(
              controller: _currentPasswordController,
              label: 'Current Password',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              validator: Validators.validatePassword,
            ),
            const SizedBox(height: 16),
            
            AuthTextField(
              controller: _newPasswordController,
              label: 'New Password',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              validator: Validators.validateStrongPassword,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            
            PasswordStrengthIndicator(
              password: _newPasswordController.text,
            ),
            const SizedBox(height: 16),
            
            AuthTextField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              validator: (value) => Validators.validateConfirmPassword(
                value,
                _newPasswordController.text,
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Change Password',
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
    );
  }

  Widget _buildSecurityOptionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          StreamBuilder<UserModel?>(
            stream: widget.authProvider.userStream,
            builder: (context, snapshot) {
              final user = widget.authProvider.user;
              final biometricEnabled = user?.privacySettings?.biometricAuth ?? false;
              
              return _buildSecurityOption(
                'Biometric Authentication',
                'Use fingerprint or face recognition',
                Icons.fingerprint,
                biometricEnabled,
                (value) async {
                  try {
                    await widget.authProvider.updatePrivacySettings(biometricAuth: value);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Biometric authentication updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update biometric settings: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              );
            },
          ),
          
          _buildSecurityOption(
            'Login Alerts',
            'Get notified of new sign-ins',
            Icons.notifications_outlined,
            true,
            (value) {
              // Placeholder for future implementation
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOption(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF1976D2), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1976D2),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await widget.authProvider.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.authProvider.errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}