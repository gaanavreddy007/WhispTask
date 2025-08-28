import 'package:flutter/material.dart';
import '../utils/validators.dart';

class PasswordStrengthIndicator extends StatefulWidget {
  final String password;
  final bool showRequirements;
  final bool showStrengthText;
  final bool compact;
  final EdgeInsets? padding;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showRequirements = true,
    this.showStrengthText = true,
    this.compact = false,
    this.padding,
  });

  @override
  State<PasswordStrengthIndicator> createState() => _PasswordStrengthIndicatorState();
}

class _PasswordStrengthIndicatorState extends State<PasswordStrengthIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(PasswordStrengthIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.password != widget.password) {
      final strength = Validators.getPasswordStrength(widget.password);
      _animationController.animateTo(strength / 5.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = Validators.getPasswordStrength(widget.password);
    final strengthText = Validators.getPasswordStrengthText(widget.password);
    final strengthColor = Validators.getPasswordStrengthColor(widget.password);

    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strength Progress Bar
          _buildStrengthBar(strength, strengthColor),
          
          if (widget.showStrengthText) ...[
            const SizedBox(height: 8),
            _buildStrengthText(strengthText, strengthColor),
          ],
          
          if (widget.showRequirements && !widget.compact) ...[
            const SizedBox(height: 12),
            _buildRequirementsList(),
          ],
        ],
      ),
    );
  }

  Widget _buildStrengthBar(int strength, Color strengthColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.compact)
          Text(
            'Password Strength',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        
        if (!widget.compact) const SizedBox(height: 8),
        
        Container(
          height: widget.compact ? 4 : 6,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(widget.compact ? 2 : 3),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Row(
                children: List.generate(5, (index) {
                  final isActive = index < (strength * _progressAnimation.value).round();
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < 4 ? (widget.compact ? 1 : 2) : 0,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? _getSegmentColor(index, strength) : Colors.transparent,
                        borderRadius: BorderRadius.circular(widget.compact ? 2 : 3),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStrengthText(String strengthText, Color strengthColor) {
    return Row(
      children: [
        Icon(
          _getStrengthIcon(strengthText),
          size: 16,
          color: strengthColor,
        ),
        const SizedBox(width: 4),
        Text(
          strengthText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: strengthColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsList() {
    final requirements = _getPasswordRequirements();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password Requirements',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        ...requirements.map((req) => _buildRequirementItem(req)),
      ],
    );
  }

  Widget _buildRequirementItem(PasswordRequirement requirement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: requirement.isMet ? Colors.green : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              requirement.isMet ? Icons.check : Icons.close,
              size: 12,
              color: requirement.isMet ? Colors.white : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              requirement.text,
              style: TextStyle(
                fontSize: 11,
                color: requirement.isMet ? Colors.green[700] : Colors.grey[600],
                fontWeight: requirement.isMet ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSegmentColor(int index, int strength) {
    if (strength <= 1) return Colors.red;
    if (strength <= 2) return index == 0 ? Colors.red : Colors.orange;
    if (strength <= 3) {
      if (index == 0) return Colors.red;
      if (index == 1) return Colors.orange;
      return Colors.yellow[700]!;
    }
    if (strength <= 4) {
      if (index == 0) return Colors.red;
      if (index == 1) return Colors.orange;
      if (index == 2) return Colors.yellow[700]!;
      return Colors.lightGreen;
    }
    return Colors.green;
  }

  IconData _getStrengthIcon(String strengthText) {
    switch (strengthText.toLowerCase()) {
      case 'very weak':
        return Icons.security;
      case 'weak':
        return Icons.shield;
      case 'fair':
        return Icons.verified_user_outlined;
      case 'good':
        return Icons.verified_user;
      case 'strong':
        return Icons.security;
      default:
        return Icons.help_outline;
    }
  }

  List<PasswordRequirement> _getPasswordRequirements() {
    final password = widget.password;
    
    return [
      PasswordRequirement(
        text: 'At least 8 characters',
        isMet: password.length >= 8,
      ),
      PasswordRequirement(
        text: 'Contains uppercase letter',
        isMet: password.contains(RegExp(r'[A-Z]')),
      ),
      PasswordRequirement(
        text: 'Contains lowercase letter',
        isMet: password.contains(RegExp(r'[a-z]')),
      ),
      PasswordRequirement(
        text: 'Contains number',
        isMet: password.contains(RegExp(r'[0-9]')),
      ),
      PasswordRequirement(
        text: 'Contains special character',
        isMet: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      ),
    ];
  }
}

class PasswordRequirement {
  final String text;
  final bool isMet;

  PasswordRequirement({
    required this.text,
    required this.isMet,
  });
}

// Compact version for inline use
class CompactPasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showText;

  const CompactPasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return PasswordStrengthIndicator(
      password: password,
      showRequirements: false,
      showStrengthText: showText,
      compact: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}

// Circular progress version
class CircularPasswordStrengthIndicator extends StatefulWidget {
  final String password;
  final double size;
  final bool showPercentage;

  const CircularPasswordStrengthIndicator({
    super.key,
    required this.password,
    this.size = 60,
    this.showPercentage = true,
  });

  @override
  State<CircularPasswordStrengthIndicator> createState() => 
      _CircularPasswordStrengthIndicatorState();
}

class _CircularPasswordStrengthIndicatorState 
    extends State<CircularPasswordStrengthIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(CircularPasswordStrengthIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.password != widget.password) {
      final strength = Validators.getPasswordStrength(widget.password);
      _animationController.animateTo(strength / 5.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.password.isEmpty) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          value: 0,
          strokeWidth: 4,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      );
    }

    final strength = Validators.getPasswordStrength(widget.password);
    final strengthColor = Validators.getPasswordStrengthColor(widget.password);
    final percentage = ((strength / 5.0) * 100).round();

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: strength / 5.0 * _progressAnimation.value,
                strokeWidth: 4,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
              ),
              if (widget.showPercentage)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(percentage * _progressAnimation.value).round()}%',
                      style: TextStyle(
                        fontSize: widget.size * 0.2,
                        fontWeight: FontWeight.bold,
                        color: strengthColor,
                      ),
                    ),
                    Text(
                      'Strong',
                      style: TextStyle(
                        fontSize: widget.size * 0.1,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}