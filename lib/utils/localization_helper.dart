import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Helper class to provide easy access to localized strings
class LocalizationHelper {
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations.of(context);
  }
  
  /// Common localized strings that can be used throughout the app
  static String getWelcomeBack(BuildContext context) => 'Welcome Back';
  static String getSignInToContinue(BuildContext context) => 'Sign in to continue managing your tasks';
  static String getEnterEmail(BuildContext context) => 'Enter your email address';
  static String getEnterPassword(BuildContext context) => 'Enter your password';
  static String getRememberMe(BuildContext context) => 'Remember me';
  static String getSignInButton(BuildContext context) => of(context).signIn;
  static String getDontHaveAccount(BuildContext context) => of(context).dontHaveAccount;
  static String getCreateAccountButton(BuildContext context) => of(context).createAccount;
  static String getForgotPasswordButton(BuildContext context) => of(context).forgotPassword;
}
