// lib/screens/signup_screen.dart
// ignore_for_file: deprecated_member_use, unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../utils/validators.dart';
import '../l10n/app_localizations.dart';
import '../services/sentry_service.dart';
import '../widgets/loading_splash_overlay.dart';

class SignupScreen extends StatefulWidget {
  final bool isLinkingAccount;
  
  const SignupScreen({
    super.key,
    this.isLinkingAccount = false,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  bool _acceptTerms = false;
  bool _showPasswordRequirements = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600), // Faster
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Faster
      vsync: this,
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1000), // Faster
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3), // Reduced distance
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut, // Simpler curve
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9, // Less dramatic scale
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut, // Simpler curve
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));


    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    
    if (!_acceptTerms) {
      _showEnhancedSnackBar(
        context,
        AppLocalizations.of(context).acceptTermsError,
        Colors.red,
        Icons.error_outline,
      );
      return;
    }

    // Show splash screen during signup
    SplashOverlay.show(
      context,
      message: widget.isLinkingAccount 
        ? AppLocalizations.of(context).loading
        : AppLocalizations.of(context).loading,
      showMessage: true,
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    bool success;
    if (widget.isLinkingAccount) {
      success = await authProvider.linkAnonymousAccount(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
      );
    } else {
      success = await authProvider.register(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
      );
    }

    // Hide splash screen
    SplashOverlay.hide();

    if (success) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context),
              Expanded(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildForm(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.isLinkingAccount 
                    ? AppLocalizations.of(context).createAccount
                    : AppLocalizations.of(context).joinWhispTask,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEnhancedHeader(),
            const SizedBox(height: 32),
            _buildEnhancedFormContainer(),
            const SizedBox(height: 24),
            _buildEnhancedSignInLink(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              widget.isLinkingAccount ? Icons.link : Icons.person_add,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.isLinkingAccount 
                  ? AppLocalizations.of(context).createAccount
                  : AppLocalizations.of(context).joinWhispTask,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.isLinkingAccount 
                  ? AppLocalizations.of(context).convertGuestAccount
                  : AppLocalizations.of(context).startOrganizingTasks,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.4,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFormContainer() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildEnhancedNameField(),
          const SizedBox(height: 20),
          _buildEnhancedEmailField(),
          const SizedBox(height: 20),
          _buildEnhancedPasswordField(),
          const SizedBox(height: 20),
          _buildEnhancedConfirmPasswordField(),
          const SizedBox(height: 28),
          _buildEnhancedTermsCheckbox(),
          const SizedBox(height: 32),
          _buildEnhancedSignupButton(),
          if (Provider.of<AuthProvider>(context).errorMessage.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildEnhancedErrorMessage(),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedNameField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF667eea).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: AuthTextField(
        controller: _nameController,
        label: AppLocalizations.of(context).fullName,
        hint: AppLocalizations.of(context).enterFullNameHint,
        prefixIcon: Icons.person_outline,
        validator: Validators.validateDisplayName,
        textInputAction: TextInputAction.next,
        autofocus: true,
        fillColor: Colors.transparent,
      ),
    );
  }

  Widget _buildEnhancedEmailField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF667eea).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: AuthTextField(
        controller: _emailController,
        label: AppLocalizations.of(context).email,
        hint: AppLocalizations.of(context).enterEmailHint,
        prefixIcon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        validator: Validators.validateEmail,
        textInputAction: TextInputAction.next,
        fillColor: Colors.transparent,
      ),
    );
  }

  Widget _buildEnhancedPasswordField() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF667eea).withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: AuthTextField(
            controller: _passwordController,
            label: AppLocalizations.of(context).password,
            hint: AppLocalizations.of(context).createPasswordHint,
            prefixIcon: Icons.lock_outline,
            obscureText: true,
            showPasswordToggle: true,
            validator: Validators.validatePassword,
            textInputAction: TextInputAction.next,
            fillColor: Colors.transparent,
            onChanged: (value) {
              setState(() {
                _showPasswordRequirements = value.isNotEmpty;
              });
            },
          ),
        ),
        if (_showPasswordRequirements) ...[
          const SizedBox(height: 16),
          _buildEnhancedPasswordStrengthIndicator(),
        ],
      ],
    );
  }

  Widget _buildEnhancedPasswordStrengthIndicator() {
    final password = _passwordController.text;
    final strength = Validators.getPasswordStrength(password);
    final strengthText = Validators.getPasswordStrengthText(password);
    final strengthColor = Validators.getPasswordStrengthColor(password);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            strengthColor.withOpacity(0.1),
            strengthColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: strengthColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: strengthColor.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: LinearProgressIndicator(
                    value: strength / 5,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: strengthColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  strengthText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEnhancedPasswordRequirements(),
        ],
      ),
    );
  }

  Widget _buildEnhancedPasswordRequirements() {
    final password = _passwordController.text;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEnhancedRequirement(AppLocalizations.of(context).atLeast8Characters, password.length >= 8),
        _buildEnhancedRequirement(AppLocalizations.of(context).containsLowercase, RegExp(r'[a-z]').hasMatch(password)),
        _buildEnhancedRequirement(AppLocalizations.of(context).containsUppercase, RegExp(r'[A-Z]').hasMatch(password)),
        _buildEnhancedRequirement(AppLocalizations.of(context).containsNumber, RegExp(r'\d').hasMatch(password)),
        _buildEnhancedRequirement(AppLocalizations.of(context).containsSpecialChar, RegExp(r'[@$!%*?&]').hasMatch(password)),
      ],
    );
  }

  Widget _buildEnhancedRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isMet 
                    ? [Colors.green.withOpacity(0.8), Colors.green.withOpacity(0.6)]
                    : [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
              boxShadow: isMet ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : [],
            ),
            child: Icon(
              isMet ? Icons.check : Icons.circle_outlined,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w500,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedConfirmPasswordField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF667eea).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: AuthTextField(
        controller: _confirmPasswordController,
        label: AppLocalizations.of(context).confirmPassword,
        hint: AppLocalizations.of(context).reenterPasswordHint,
        prefixIcon: Icons.lock_outline,
        obscureText: true,
        showPasswordToggle: true,
        validator: (value) => Validators.validateConfirmPassword(
          value,
          _passwordController.text,
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _handleSignup(),
        fillColor: Colors.transparent,
      ),
    );
  }

  Widget _buildEnhancedTermsCheckbox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: _acceptTerms 
                  ? const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    )
                  : LinearGradient(
                      colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
                    ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _acceptTerms ? Colors.transparent : Colors.white.withOpacity(0.4),
              ),
              boxShadow: _acceptTerms ? [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : [],
            ),
            child: Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: _acceptTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptTerms = value ?? false;
                  });
                },
                visualDensity: VisualDensity.compact,
                activeColor: Colors.transparent,
                checkColor: Colors.white,
                side: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _acceptTerms = !_acceptTerms;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    children: [
                      TextSpan(text: AppLocalizations.of(context).iAgreeToTerms),
                      TextSpan(
                        text: AppLocalizations.of(context).termsOfService,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    TextSpan(text: AppLocalizations.of(context).and),
                    TextSpan(
                      text: AppLocalizations.of(context).privacyPolicy,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSignupButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : _handleSignup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: authProvider.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.isLinkingAccount 
                          ? AppLocalizations.of(context).createAccount 
                          : AppLocalizations.of(context).signUp,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedSignInLink() {
    if (widget.isLinkingAccount) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Center(
        child: TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
              children: [
                TextSpan(text: AppLocalizations.of(context).alreadyHaveAccount),
                const TextSpan(
                  text: ' ',
                ),
                TextSpan(
                  text: AppLocalizations.of(context).signIn,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.2),
            Colors.red.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.redAccent],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              Provider.of<AuthProvider>(context).errorMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEnhancedSnackBar(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}