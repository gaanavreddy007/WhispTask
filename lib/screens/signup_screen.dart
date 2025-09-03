// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../utils/validators.dart';
import '../l10n/app_localizations.dart';

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
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _acceptTerms = false;
  bool _showPasswordRequirements = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
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
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).acceptTermsError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildForm(),
              ),
            );
          },
        ),
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
            _buildHeader(),
            const SizedBox(height: 32),
            _buildNameField(),
            const SizedBox(height: 20),
            _buildEmailField(),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 20),
            _buildConfirmPasswordField(),
            const SizedBox(height: 24),
            _buildTermsCheckbox(),
            const SizedBox(height: 32),
            _buildSignupButton(),
            const SizedBox(height: 16),
            _buildSignInLink(),
            if (Provider.of<AuthProvider>(context).errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildErrorMessage(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isLinkingAccount ? AppLocalizations.of(context).createAccount : AppLocalizations.of(context).joinWhispTask,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.isLinkingAccount 
              ? AppLocalizations.of(context).convertGuestAccount
              : AppLocalizations.of(context).startOrganizingTasks,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return AuthTextField(
      controller: _nameController,
      label: AppLocalizations.of(context).fullName,
      hint: AppLocalizations.of(context).enterFullNameHint,
      prefixIcon: Icons.person_outline,
      validator: Validators.validateDisplayName,
      textInputAction: TextInputAction.next,
      autofocus: true,
    );
  }

  Widget _buildEmailField() {
    return AuthTextField(
      controller: _emailController,
      label: AppLocalizations.of(context).email,
      hint: AppLocalizations.of(context).enterEmailHint,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: Validators.validateEmail,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField() {
    return Column(
      children: [
        AuthTextField(
          controller: _passwordController,
          label: AppLocalizations.of(context).password,
          hint: AppLocalizations.of(context).createPasswordHint,
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          showPasswordToggle: true,
          validator: Validators.validatePassword,
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            setState(() {
              _showPasswordRequirements = value.isNotEmpty;
            });
          },
        ),
        if (_showPasswordRequirements) ...[
          const SizedBox(height: 12),
          _buildPasswordStrengthIndicator(),
        ],
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    final strength = Validators.getPasswordStrength(password);
    final strengthText = Validators.getPasswordStrengthText(password);
    final strengthColor = Validators.getPasswordStrengthColor(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength / 5,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                minHeight: 4,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              strengthText,
              style: TextStyle(
                fontSize: 12,
                color: strengthColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildPasswordRequirements(),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirement(AppLocalizations.of(context).atLeast8Characters, password.length >= 8),
        _buildRequirement(AppLocalizations.of(context).containsLowercase, RegExp(r'[a-z]').hasMatch(password)),
        _buildRequirement(AppLocalizations.of(context).containsUppercase, RegExp(r'[A-Z]').hasMatch(password)),
        _buildRequirement(AppLocalizations.of(context).containsNumber, RegExp(r'\d').hasMatch(password)),
        _buildRequirement(AppLocalizations.of(context).containsSpecialChar, RegExp(r'[@$!%*?&]').hasMatch(password)),
      ],
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? Colors.green : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? Colors.green : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return AuthTextField(
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
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptTerms = !_acceptTerms;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  children: [
                    TextSpan(text: AppLocalizations.of(context).iAgreeToTerms),
                    TextSpan(
                      text: AppLocalizations.of(context).termsOfService,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(text: AppLocalizations.of(context).and),
                    TextSpan(
                      text: AppLocalizations.of(context).privacyPolicy,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.isLinkingAccount ? AppLocalizations.of(context).createAccount : AppLocalizations.of(context).signUp,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSignInLink() {
    if (widget.isLinkingAccount) {
      return const SizedBox.shrink();
    }

    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            children: [
              TextSpan(text: AppLocalizations.of(context).alreadyHaveAccount),
              TextSpan(
                text: AppLocalizations.of(context).signIn,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              Provider.of<AuthProvider>(context).errorMessage,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}