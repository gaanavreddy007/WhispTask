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
import '../models/task.dart';
import '../l10n/app_localizations.dart';
import '../services/biometric_service.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Transform.translate(
                offset: const Offset(8, 0),
                child: Material(
                  color: colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.onSurface.withOpacity(0.2)),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              AppLocalizations.of(context).accountSettings,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            centerTitle: false,
            titleSpacing: 32,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withOpacity(0.1),
                      colorScheme.secondary.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return StreamBuilder<SyncStatus>(
                    stream: authProvider.syncStatusStream,
                    builder: (context, snapshot) {
                      final status = snapshot.data ?? SyncStatus.idle;
                      return Container(
                        margin: const EdgeInsets.only(right: 16, top: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: status == SyncStatus.syncing ? null : () => authProvider.forceSyncUserData(),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surface.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _getSyncIcon(status),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: colorScheme.onPrimary,
                  unselectedLabelColor: colorScheme.onSurface.withOpacity(0.7),
                  indicator: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorPadding: const EdgeInsets.all(4),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  tabs: [
                    Tab(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.security, size: 16),
                            const SizedBox(width: 4),
                            Text(AppLocalizations.of(context).security),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.privacy_tip, size: 16),
                            const SizedBox(width: 4),
                            Text(AppLocalizations.of(context).privacy),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_circle, size: 16),
                            const SizedBox(width: 4),
                            Text(AppLocalizations.of(context).account),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: Consumer<AuthProvider>(
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
          ),
        ],
      ),
    );
  }

  Widget _getSyncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        );
      case SyncStatus.success:
        return const Icon(Icons.cloud_done, color: Colors.green, size: 20);
      case SyncStatus.error:
        return const Icon(Icons.cloud_off, color: Colors.red, size: 20);
      case SyncStatus.offline:
        return const Icon(Icons.cloud_queue, color: Colors.orange, size: 20);
      default:
        return Icon(Icons.cloud, color: Colors.grey[600], size: 20);
    }
  }
}

// SECURITY TAB - Password changes, biometric auth, security status
class _SecurityTab extends StatefulWidget {
  final AuthProvider authProvider;
  
  const _SecurityTab({required this.authProvider});

  @override
  State<_SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<_SecurityTab> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authProvider.user;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildStatusCard(user),
            const SizedBox(height: 20),
            if (!user!.isAnonymous) _buildChangePasswordCard(),
            const SizedBox(height: 20),
            _buildSecurityOptionsCard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(user) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: user.isAnonymous ? [
                    Colors.orange.withOpacity(0.1),
                    Colors.amber.withOpacity(0.05),
                  ] : [
                    Colors.green.withOpacity(0.1),
                    Colors.teal.withOpacity(0.05),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: user.isAnonymous 
                        ? Colors.orange.withOpacity(0.15) 
                        : Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      user.isAnonymous ? Icons.warning_amber : Icons.verified_user,
                      color: user.isAnonymous ? Colors.orange : Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).accountSecurity,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildSecurityItem(
                    AppLocalizations.of(context).accountType,
                    user.accountType,
                    user.isAnonymous ? Icons.warning_amber : Icons.check_circle,
                    user.isAnonymous ? Colors.orange : Colors.green,
                  ),
                  
                  if (!user.isAnonymous) ...[
                    const SizedBox(height: 16),
                    _buildSecurityItem(
                      AppLocalizations.of(context).emailVerified,
                      AppLocalizations.of(context).emailVerified,
                      Icons.verified,
                      Colors.green,
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  _buildSecurityItem(
                    AppLocalizations.of(context).lastSignIn,
                    user.formattedLastSignIn,
                    Icons.schedule,
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityItem(String label, String value, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordCard() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.indigo.withOpacity(0.05),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).changePassword,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthTextField(
                      controller: _currentPasswordController,
                      label: AppLocalizations.of(context).password,
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      validator: Validators.validatePassword,
                    ),
                    const SizedBox(height: 20),
                    
                    AuthTextField(
                      controller: _newPasswordController,
                      label: AppLocalizations.of(context).password,
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      validator: Validators.validateStrongPassword,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    
                    PasswordStrengthIndicator(
                      password: _newPasswordController.text,
                    ),
                    const SizedBox(height: 20),
                    
                    AuthTextField(
                      controller: _confirmPasswordController,
                      label: AppLocalizations.of(context).confirmPassword,
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) => Validators.validateConfirmPassword(
                        value,
                        _newPasswordController.text,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
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
                            : Text(
                                AppLocalizations.of(context).changePassword,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityOptionsCard() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.withOpacity(0.1),
                    Colors.deepPurple.withOpacity(0.05),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Colors.purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    AppLocalizations.of(context).security,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  StreamBuilder<UserModel?>(
                    stream: widget.authProvider.userStream,
                    builder: (context, snapshot) {
                      final user = widget.authProvider.user;
                      final biometricEnabled = user?.privacySettings?.biometricAuth ?? false;
                      
                      return _buildSecurityOption(
                        AppLocalizations.of(context).biometricAuthentication,
                        AppLocalizations.of(context).biometricAuthenticationDescription,
                        Icons.fingerprint,
                        biometricEnabled,
                        (value) async {
                          await _handleBiometricToggle(value);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<UserModel?>(
                    stream: widget.authProvider.userStream,
                    builder: (context, snapshot) {
                      final user = widget.authProvider.user;
                      final loginAlertsEnabled = user?.privacySettings?.shareAnalytics ?? false;
                      
                      return _buildSecurityOption(
                        AppLocalizations.of(context).loginAlerts,
                        AppLocalizations.of(context).loginAlertsDescription,
                        Icons.notifications_outlined,
                        loginAlertsEnabled,
                        (value) async {
                          try {
                            await widget.authProvider.updatePrivacySettings(enableAnalytics: value);
                            _showSuccessSnackBar(value 
                              ? 'Login alerts enabled successfully' 
                              : 'Login alerts disabled successfully');
                          } catch (e) {
                            _showErrorSnackBar('Failed to update login alerts');
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleBiometricToggle(bool value) async {
    print('SecurityTab: Biometric toggle called with value: $value');
    try {
      if (value) {
        // Enabling biometric authentication
        print('SecurityTab: Enabling biometric authentication');
        final bool isAvailable = await BiometricService.isBiometricAvailable();
        print('SecurityTab: Biometric available: $isAvailable');
        
        if (!isAvailable) {
          _showErrorSnackBar('Biometric authentication is not available on this device');
          return;
        }

        // Test biometric authentication before enabling
        print('SecurityTab: Testing biometric authentication');
        final bool authenticated = await BiometricService.authenticate(
          reason: 'Please authenticate to enable biometric login',
        );
        print('SecurityTab: Authentication result: $authenticated');

        if (!authenticated) {
          _showErrorSnackBar('Biometric authentication failed');
          return;
        }

        // Update the setting
        print('SecurityTab: Updating biometric setting to true');
        await widget.authProvider.updatePrivacySettings(biometricAuth: true);
        _showSuccessSnackBar('Biometric authentication enabled successfully');
        print('SecurityTab: Biometric authentication enabled successfully');
      } else {
        // Disabling biometric authentication - require authentication first
        print('SecurityTab: Disabling biometric authentication');
        final bool authenticated = await BiometricService.authenticate(
          reason: 'Please authenticate to disable biometric login',
        );
        print('SecurityTab: Disable authentication result: $authenticated');

        if (!authenticated) {
          _showErrorSnackBar('Authentication required to change biometric settings');
          return;
        }

        // Update the setting
        print('SecurityTab: Updating biometric setting to false');
        await widget.authProvider.updatePrivacySettings(biometricAuth: false);
        _showSuccessSnackBar('Biometric authentication disabled');
        print('SecurityTab: Biometric authentication disabled successfully');
      }
    } catch (e) {
      print('Biometric toggle error: $e');
      _showErrorSnackBar('Failed to update biometric settings: ${e.toString()}');
    }
  }

  Future<void> _changePassword() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

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
      
      _showSuccessSnackBar(AppLocalizations.of(context).passwordChangedSuccess);
    } else {
      _showErrorSnackBar(widget.authProvider.errorMessage);
    }
  }
}

// PRIVACY TAB - Data privacy, analytics, notifications, language
class _PrivacyTab extends StatefulWidget {
  final AuthProvider authProvider;
  
  const _PrivacyTab({required this.authProvider});

  @override
  State<_PrivacyTab> createState() => _PrivacyTabState();
}

class _PrivacyTabState extends State<_PrivacyTab> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
    
    // Listen for user data changes to trigger rebuilds
    widget.authProvider.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildDataPrivacyCard(),
            const SizedBox(height: 20),
            _buildNotificationPreferencesCard(),
            const SizedBox(height: 20),
            _buildLanguagePreferencesCard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPrivacyCard() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.withOpacity(0.1),
                    Colors.deepPurple.withOpacity(0.05),
                  ],
                  ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.privacy_tip,
                      color: Colors.purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).dataPrivacy,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildPrivacyOption(
                    AppLocalizations.of(context).analyticsData,
                    AppLocalizations.of(context).analyticsDataDescription,
                    Icons.analytics_outlined,
                    widget.authProvider.user?.privacySettings?.shareAnalytics ?? true,
                    (value) async {
                      try {
                        await widget.authProvider.updatePrivacySettings(enableAnalytics: value);
                        _showSuccessSnackBar(AppLocalizations.of(context).analyticsSettingsUpdated);
                        print('PrivacyTab: Analytics updated to $value');
                        // Trigger rebuild to show new state
                        setState(() {});
                      } catch (e) {
                        _showErrorSnackBar('Failed to update analytics settings: $e');
                        print('PrivacyTab: Failed to update analytics: $e');
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPrivacyOption(
                    AppLocalizations.of(context).crashReports,
                    AppLocalizations.of(context).crashReportsDescription,
                    Icons.bug_report_outlined,
                    widget.authProvider.user?.privacySettings?.shareCrashReports ?? true,
                    (value) async {
                      try {
                        await widget.authProvider.updatePrivacySettings(shareUsageData: value);
                        _showSuccessSnackBar(AppLocalizations.of(context).crashReportSettingsUpdated);
                        print('PrivacyTab: Crash reports updated to $value');
                        // Trigger rebuild to show new state
                        setState(() {});
                      } catch (e) {
                        _showErrorSnackBar('Failed to update crash report settings: $e');
                        print('PrivacyTab: Failed to update crash reports: $e');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationPreferencesCard() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.indigo.withOpacity(0.1),
                    Colors.blue.withOpacity(0.05),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.indigo,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).notifications,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildPrivacyOption(
                AppLocalizations.of(context).notifications,
                'Receive task reminders and app updates',
                Icons.push_pin_outlined,
                widget.authProvider.user?.preferences.notificationsEnabled ?? true,
                (value) async {
                  try {
                    final currentPrefs = widget.authProvider.userPreferences ?? UserPreferences.defaultPreferences();
                    final updatedPrefs = currentPrefs.copyWith(notificationsEnabled: value);
                    await widget.authProvider.updateUserPreferences(updatedPrefs);
                    _showSuccessSnackBar('Settings updated');
                    print('PrivacyTab: Push notifications updated to $value');
                    // Trigger rebuild to show new state
                    setState(() {});
                  } catch (e) {
                    _showErrorSnackBar('Failed to update notification settings: $e');
                    print('PrivacyTab: Failed to update notifications: $e');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLanguagePreferencesCard() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.withOpacity(0.1),
                    Colors.teal.withOpacity(0.05),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.language,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).language,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildActionButton(
                AppLocalizations.of(context).language,
                AppLocalizations.of(context).selectLanguage,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementCard() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.withOpacity(0.1),
                    Colors.amber.withOpacity(0.05),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.storage,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Data Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildActionButton(
                    'Export Data',
                    'Download a copy of your tasks and account data',
                    Icons.download_outlined,
                    Colors.blue,
                    _exportData,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    'Import Data',
                    'Restore data from a previous export',
                    Icons.upload_outlined,
                    Colors.green,
                    _importData,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    'Clear Cache',
                    'Clear locally stored app data and preferences',
                    Icons.clear_all,
                    Colors.orange,
                    _clearCache,
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon, 
              color: colorScheme.primary, 
              size: 20,
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
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch.adaptive(
            value: value,
            onChanged: (newValue) {
              // Execute async operation without blocking UI
              onChanged(newValue);
            },
            activeColor: colorScheme.primary,
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _exportData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildLoadingDialog(AppLocalizations.of(context).loading),
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.exportUserData();
      
      Navigator.of(context).pop();
      
      if (result != null) {
        showDialog(
          context: context,
          builder: (context) => _buildExportSuccessDialog(result),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar(AppLocalizations.of(context).exportFailed);
    }
  }

  void _importData() async {
    showDialog(
      context: context,
      builder: (context) => _buildImportDialog(),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => _buildClearCacheDialog(),
    );
  }

  Widget _buildLoadingDialog(String message) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSuccessDialog(Map<String, dynamic> result) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            Text(
              'Export Complete',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).exportCompleteDescription),
            const SizedBox(height: 16),
            Text(
              'File size: ${(jsonEncode(result).length / 1024).toStringAsFixed(1)} KB',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: jsonEncode(result)));
                      Navigator.of(context).pop();
                      _showSuccessSnackBar('Data copied to clipboard');
                    },
                    child: Text('Copy to Clipboard'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.upload, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Import Data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('Choose how to import your data:'),
            const SizedBox(height: 16),
            const Text(
              'Note: This will merge with your existing data. Duplicate tasks will be skipped.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context).cancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _importFromClipboard();
                    },
                    child: const Text('From Clipboard'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearCacheDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Clear Cache',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'This will clear locally stored data and preferences. Your account data will remain safe in the cloud. Continue?',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context).cancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      
                      try {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => _buildLoadingDialog('Clearing cache...'),
                        );

                        await widget.authProvider.clearUserCache();
                        
                        Navigator.of(context).pop();
                        
                        _showSuccessSnackBar('Cache cleared successfully!');
                      } catch (e) {
                        Navigator.of(context).pop();
                        _showErrorSnackBar('Failed to clear cache: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final clipboardText = clipboardData?.text;
      
      if (clipboardText == null || clipboardText.isEmpty) {
        _showErrorSnackBar('Clipboard is empty or contains no text');
        return;
      }

      // Try to parse as JSON
      try {
        final jsonData = jsonDecode(clipboardText);
        
        if (jsonData is Map<String, dynamic>) {
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => _buildLoadingDialog('Importing data...'),
          );

          // Import tasks if available
          if (jsonData.containsKey('tasks') && jsonData['tasks'] is List) {
            final taskProvider = Provider.of<TaskProvider>(context, listen: false);
            final tasks = jsonData['tasks'] as List;
            
            int importedCount = 0;
            for (final taskData in tasks) {
              if (taskData is Map<String, dynamic>) {
                try {
                  // Create task from imported data with generated ID
                  final taskId = taskData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
                  final task = Task.fromMap(taskData, taskId);
                  await taskProvider.addTask(task);
                  importedCount++;
                } catch (e) {
                  print('Failed to import task: $e');
                }
              }
            }
            
            Navigator.of(context).pop(); // Close loading dialog
            _showSuccessSnackBar('Successfully imported $importedCount tasks from clipboard');
          } else {
            Navigator.of(context).pop(); // Close loading dialog
            _showErrorSnackBar('No valid task data found in clipboard');
          }
        } else {
          _showErrorSnackBar('Invalid data format in clipboard');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to parse clipboard data: Invalid JSON format');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to access clipboard: $e');
    }
  }
}

// ACCOUNT TAB - Premium status, account info, sync status, theme, dangerous actions
class _AccountTab extends StatefulWidget {
  final AuthProvider authProvider;
  
  const _AccountTab({required this.authProvider});

  @override
  State<_AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<_AccountTab> with TickerProviderStateMixin {
  bool _isDeleting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authProvider.user!;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildPremiumStatusCard(),
            const SizedBox(height: 20),
            _buildAccountInfoCard(user),
            const SizedBox(height: 20),
            _buildSyncStatusCard(),
            const SizedBox(height: 20),
            _buildAccountActionsCard(user),
            const SizedBox(height: 20),
            _buildDangerZoneCard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumStatusCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final isPremium = widget.authProvider.isPremium;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isPremium
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber.shade100,
                  Colors.orange.shade50,
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surfaceVariant.withOpacity(0.3),
                  colorScheme.surface,
                ],
              ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(
          color: isPremium ? Colors.amber.withOpacity(0.3) : colorScheme.outline.withOpacity(0.1),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPremium ? Colors.amber.withOpacity(0.2) : colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isPremium ? Icons.star : Icons.star_outline,
                    color: isPremium ? Colors.amber.shade700 : colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    isPremium ? 'Premium User' : 'Upgrade to Pro',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isPremium ? Colors.amber.shade700 : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isPremium) PremiumHelper.buildPremiumBadge(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isPremium 
                  ? AppLocalizations.of(context).enjoyingPremiumFeatures 
                  : AppLocalizations.of(context).unlockPremiumDescription,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.8),
                fontSize: 15,
              ),
            ),
            if (!isPremium) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.authProvider.isLoading ? null : () {
                    Navigator.pushNamed(context, '/premium-purchase');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
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
                          'Upgrade to Pro - ₹149/month',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard(user) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.withOpacity(0.1),
                    Colors.teal.withOpacity(0.05),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.account_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).profileInformation,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildInfoRow('User ID', user.uid.substring(0, 8) + '...'),
                  _buildInfoRow(AppLocalizations.of(context).accountType, user.accountType),
                  if (user.email?.isNotEmpty ?? false)
                    _buildInfoRow(AppLocalizations.of(context).email, user.email!),
                  _buildInfoRow(AppLocalizations.of(context).memberSince, user.memberSince),
                  _buildInfoRow(AppLocalizations.of(context).totalTasks, user.taskCount.toString()),
                  _buildInfoRow(AppLocalizations.of(context).completed, user.completedTaskCount.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.withOpacity(0.1),
                    Colors.cyan.withOpacity(0.05),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.sync,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Sync Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: StreamBuilder<SyncStatus>(
                stream: widget.authProvider.syncStatusStream,
                builder: (context, snapshot) {
                  final status = snapshot.data ?? SyncStatus.idle;
                  final statusInfo = _getSyncStatusInfo(status);
                  
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: statusInfo['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                statusInfo['icon'],
                                color: statusInfo['color'],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    statusInfo['title'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    statusInfo['subtitle'],
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (status != SyncStatus.syncing)
                              Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.refresh,
                                    color: colorScheme.primary,
                                  ),
                                  onPressed: () => widget.authProvider.forceSyncUserData(),
                                  tooltip: 'Force sync',
                                ),
                              ),
                          ],
                        ),
                        if (status == SyncStatus.syncing) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              backgroundColor: colorScheme.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildAccountActionsCard(user) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.withOpacity(0.1),
                    Colors.indigo.withOpacity(0.05),
                  ],
                ),
              ),
              child: Text(
                AppLocalizations.of(context).accountActions,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (user.isAnonymous)
                    _buildActionButton(
                      AppLocalizations.of(context).upgradeAccount,
                      AppLocalizations.of(context).upgradeAccountDesc,
                      Icons.upgrade_outlined,
                      Colors.green,
                      () => Navigator.pushNamed(context, '/signup', arguments: true),
                    )
                  else
                    _buildActionButton(
                      AppLocalizations.of(context).downloadAccountData,
                      AppLocalizations.of(context).downloadAccountDataDescription,
                      Icons.download_outlined,
                      Colors.blue,
                      _downloadAccountData,
                    ),
                  
                  const SizedBox(height: 16),
                  
                  _buildActionButton(
                    AppLocalizations.of(context).contactSupport,
                    AppLocalizations.of(context).getHelpDescription,
                    Icons.support_agent_outlined,
                    Colors.purple,
                    _contactSupport,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return _buildThemeSelector(themeProvider);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(
          color: Colors.red.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.withOpacity(0.1),
                    Colors.pink.withOpacity(0.05),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.warning,
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).dangerZone,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildDangerButton(
                    AppLocalizations.of(context).deleteTask,
                    AppLocalizations.of(context).deleteAllTasksDescription,
                    Icons.delete_outline,
                    _deleteAllTasks,
                  ),
                  const SizedBox(height: 16),
                  _buildDangerButton(
                    AppLocalizations.of(context).delete,
                    AppLocalizations.of(context).deleteAccountDescription,
                    Icons.delete_forever,
                    _deleteAccount,
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: color,
                ),
              ),
            ],
          ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.red.shade700, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).theme,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  context: context,
                  themeProvider: themeProvider,
                  themeMode: ThemeMode.light,
                  title: AppLocalizations.of(context).lightMode,
                  icon: Icons.light_mode,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  context: context,
                  themeProvider: themeProvider,
                  themeMode: ThemeMode.dark,
                  title: AppLocalizations.of(context).darkMode,
                  icon: Icons.dark_mode,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  context: context,
                  themeProvider: themeProvider,
                  themeMode: ThemeMode.system,
                  title: AppLocalizations.of(context).systemMode,
                  icon: Icons.settings_system_daydream,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeProvider themeProvider,
    required ThemeMode themeMode,
    required String title,
    required IconData icon,
  }) {
    final isSelected = themeProvider.themeMode == themeMode;
    
    return GestureDetector(
      onTap: () => themeProvider.setThemeMode(themeMode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _downloadAccountData() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildLoadingDialog(AppLocalizations.of(context).downloadAccountData),
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.exportUserData();
      
      Navigator.of(context).pop();
      
      if (result != null) {
        showDialog(
          context: context,
          builder: (context) => _buildExportSuccessDialog(result),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar(AppLocalizations.of(context).exportFailed);
    }
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.support_agent, color: Colors.purple, size: 48),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).contactSupport,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).needHelpContactUs),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: Text(AppLocalizations.of(context).emailSupport),
                subtitle: const Text('support@whispTask.com'),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.chat_outlined),
                title: Text(AppLocalizations.of(context).liveChat),
                subtitle: Text(AppLocalizations.of(context).availableHours),
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context).cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteAllTasks() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).deleteTask,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).deleteAllTasksConfirmation,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppLocalizations.of(context).cancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                        final success = await taskProvider.deleteAllUserTasks();
                        
                        if (success) {
                          _showSuccessSnackBar(AppLocalizations.of(context).taskDeleted);
                        } else {
                          _showErrorSnackBar(AppLocalizations.of(context).failedToDeleteTasks);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(AppLocalizations.of(context).delete),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_forever, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).delete,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).deleteAccountConfirmation,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppLocalizations.of(context).cancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showDeleteAccountConfirmation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(AppLocalizations.of(context).delete),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    final passwordController = TextEditingController();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).confirmAccountDeletion,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).enterPasswordToConfirm),
              const SizedBox(height: 16),
              if (!authProvider.user!.isAnonymous)
                AuthTextField(
                  controller: passwordController,
                  label: AppLocalizations.of(context).password,
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: Validators.validatePassword,
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppLocalizations.of(context).cancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
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
                          : Text(AppLocalizations.of(context).delete),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(String password) async {
    setState(() => _isDeleting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.deleteAccount(
      password: authProvider.user!.isAnonymous ? null : password,
    );

    if (mounted) {
      setState(() => _isDeleting = false);
      Navigator.of(context).pop();

      if (success) {
        _showSuccessSnackBar(AppLocalizations.of(context).accountDeletedSuccessfully);
      } else {
        _showErrorSnackBar(authProvider.errorMessage);
      }
    }
  }

  Widget _buildLoadingDialog(String message) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSuccessDialog(Map<String, dynamic> result) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).exportCompleteDescription,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).exportCompleteDescription),
            const SizedBox(height: 16),
            Text(
              'File size: ${(jsonEncode(result).length / 1024).toStringAsFixed(1)} KB',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: jsonEncode(result)));
                      Navigator.of(context).pop();
                      _showSuccessSnackBar(AppLocalizations.of(context).exportCompleteDescription);
                    },
                    child: Text(AppLocalizations.of(context).save),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context).save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}