// lib/widgets/auth_text_field.dart
// ignore_for_file: use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  final Widget? suffix;
  final int maxLines;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final bool showPasswordToggle;
  final Color? fillColor;
  final bool autofocus;

  const AuthTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.suffix,
    this.maxLines = 1,
    this.textInputAction,
    this.onSubmitted,
    this.showPasswordToggle = false,
    this.fillColor,
    this.autofocus = false,
  }) : super(key: key);

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = false;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: _hasFocus ? const Color(0xFF667eea) : const Color(0xFF64748B),
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              _hasFocus = hasFocus;
            });
          },
          child: TextFormField(
            controller: widget.controller,
            obscureText: _obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            onChanged: widget.onChanged,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            autofocus: widget.autofocus,
            style: TextStyle(
              fontSize: 16,
              color: widget.enabled ? null : Colors.grey[600],
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _hasFocus 
                          ? const Color(0xFF667eea) 
                          : const Color(0xFF64748B),
                    )
                  : null,
              suffixIcon: _buildSuffixIcon(),
              filled: true,
              fillColor: widget.fillColor ?? 
                  (widget.enabled 
                      ? Colors.white.withOpacity(0.9) 
                      : Colors.grey[200]),
              border: widget.fillColor == Colors.transparent 
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
              enabledBorder: widget.fillColor == Colors.transparent 
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFF667eea).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
              focusedBorder: widget.fillColor == Colors.transparent 
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF667eea),
                        width: 2,
                      ),
                    ),
              errorBorder: widget.fillColor == Colors.transparent 
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1,
                      ),
                    ),
              focusedErrorBorder: widget.fillColor == Colors.transparent 
                  ? InputBorder.none
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey[400]!,
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              errorStyle: const TextStyle(
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.showPasswordToggle && widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey[600],
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    return widget.suffix;
  }
}