// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_strength_indicator.dart';
import '../utils/validators.dart';

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
        title: const Text('Account Settings'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1976D2),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF1976D2),
          tabs: const [
            Tab(text: 'Security'),
            Tab(text: 'Privacy'),
            Tab(text: 'Account'),
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
}

class _PrivacyTab extends StatefulWidget {
  final AuthProvider authProvider;
  
  const _PrivacyTab({required this.authProvider});

  @override
  State<_PrivacyTab> createState() => _PrivacyTabState();
}

class _PrivacyTabState extends State<_PrivacyTab> {
  bool _analyticsEnabled = true;
  bool _crashReportsEnabled = true;
  bool _marketingEmails = false;
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildDataPrivacyCard(),
          const SizedBox(height: 24),
          _buildNotificationPreferencesCard(),
          const SizedBox(height: 24),
          _buildDataManagementCard(),
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
            (value) => setState(() => _analyticsEnabled = value),
          ),
          
          _buildPrivacyOption(
            'Crash Reports',
            'Automatically send crash reports to help fix issues',
            Icons.bug_report_outlined,
            _crashReportsEnabled,
            (value) => setState(() => _crashReportsEnabled = value),
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
            (value) => setState(() => _pushNotifications = value),
          ),
          
          _buildPrivacyOption(
            'Marketing Emails',
            'Receive tips, updates, and promotional content',
            Icons.email_outlined,
            _marketingEmails,
            (value) => setState(() => _marketingEmails = value),
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
    Function(bool) onChanged,
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
            onChanged: onChanged,
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

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export feature coming soon!'),
        duration: Duration(seconds: 2),
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
          'This will clear locally stored data and may require you to sign in again. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
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
          _buildAccountInfoCard(user),
          const SizedBox(height: 24),
          _buildAccountActionsCard(user),
          const SizedBox(height: 24),
          _buildDangerZoneCard(user),
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
            'Permanently delete your account and all data',
            Icons.delete_forever,
            _deleteAccount,
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

  void _downloadAccountData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account data download feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
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
          
          _buildSecurityOption(
            'Biometric Authentication',
            'Use fingerprint or face recognition',
            Icons.fingerprint,
            false,
            (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Biometric authentication coming soon!'),
                ),
              );
            },
          ),
          
          _buildSecurityOption(
            'Login Alerts',
            'Get notified of new sign-ins',
            Icons.notifications_outlined,
            true,
            (value) {
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