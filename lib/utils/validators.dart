import 'package:flutter/material.dart';

class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    return null;
  }

  // Strong password validation
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    if (!RegExp(r'[@$!%*?&]').hasMatch(value)) {
      return 'Password must contain at least one special character (@\$!%*?&)';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    // Check if name contains only letters, spaces, apostrophes, and hyphens
    if (!RegExp(r"^[a-zA-Z\s'\-]+$").hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, apostrophes, and hyphens';
    }
    
    return null;
  }

  // Display name validation (more flexible than name)
  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Display name must be at least 2 characters long';
    }
    
    if (value.trim().length > 30) {
      return 'Display name must be less than 30 characters';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters
    String cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanNumber.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (cleanNumber.length > 15) {
      return 'Phone number must be less than 15 digits';
    }
    
    return null;
  }

  // Optional phone number validation
  static String? validateOptionalPhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    
    return validatePhoneNumber(value);
  }

  // Generic required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }

  // Generic length validation
  static String? validateLength(String? value, String fieldName, int minLength, [int? maxLength]) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    
    if (maxLength != null && value.trim().length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    
    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    
    try {
      Uri.parse(value.trim());
      if (!value.trim().startsWith('http://') && !value.trim().startsWith('https://')) {
        return 'URL must start with http:// or https://';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }

  // Age validation
  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }
    
    int? age = int.tryParse(value.trim());
    if (age == null) {
      return 'Please enter a valid age';
    }
    
    if (age < 13) {
      return 'You must be at least 13 years old';
    }
    
    if (age > 120) {
      return 'Please enter a valid age';
    }
    
    return null;
  }

  // Date validation (for string dates)
  static String? validateDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Date is required';
    }
    
    try {
      DateTime.parse(value.trim());
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  // Combination validator (combines multiple validators)
  static String? Function(String?) combineValidators(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }

  // Check if email is disposable (basic check)
  static bool isDisposableEmail(String email) {
    final disposableDomains = [
      '10minutemail.com',
      'tempmail.org',
      'guerrillamail.com',
      'mailinator.com',
      'temp-mail.org',
      'throwaway.email',
      // Add more disposable email domains as needed
    ];
    
    final domain = email.split('@').last.toLowerCase();
    return disposableDomains.contains(domain);
  }

  // Validate email is not disposable
  static String? validatePermanentEmail(String? value) {
    final emailValidation = validateEmail(value);
    if (emailValidation != null) return emailValidation;
    
    if (isDisposableEmail(value!)) {
      return 'Please use a permanent email address';
    }
    
    return null;
  }

  // Password strength score (0-4)
  static int getPasswordStrength(String password) {
    int score = 0;
    
    if (password.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[@$!%*?&]').hasMatch(password)) score++;
    
    return score;
  }

  // Get password strength description
  static String getPasswordStrengthText(String password) {
    int strength = getPasswordStrength(password);
    switch (strength) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      case 5:
        return 'Very Strong';
      default:
        return 'Unknown';
    }
  }

  // Get password strength color
  static Color getPasswordStrengthColor(String password) {
    int strength = getPasswordStrength(password);
    switch (strength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}