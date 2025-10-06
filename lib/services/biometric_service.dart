// ignore_for_file: avoid_print

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate using biometrics
  static Future<bool> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw Exception('Biometric authentication is not available on this device');
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.message}');
      
      // Handle specific error cases
      switch (e.code) {
        case 'NotAvailable':
          throw Exception('Biometric authentication is not available');
        case 'NotEnrolled':
          throw Exception('No biometric credentials are enrolled');
        case 'LockedOut':
          throw Exception('Biometric authentication is temporarily locked');
        case 'PermanentlyLockedOut':
          throw Exception('Biometric authentication is permanently locked');
        default:
          // Check for FragmentActivity error
          if (e.message?.contains('FragmentActivity') == true || 
              e.message?.contains('requires activity to be a FragmentActivity') == true) {
            throw Exception('App configuration error. Please restart the app and try again.');
          }
          throw Exception('Biometric authentication failed: ${e.message}');
      }
    } catch (e) {
      print('Unexpected biometric authentication error: $e');
      throw Exception('Biometric authentication failed');
    }
  }

  /// Get biometric status information
  static Future<BiometricStatus> getBiometricStatus() async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricStatus.notAvailable;
      }

      final List<BiometricType> availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return BiometricStatus.notEnrolled;
      }

      return BiometricStatus.available;
    } catch (e) {
      print('Error getting biometric status: $e');
      return BiometricStatus.notAvailable;
    }
  }

  /// Get user-friendly biometric type names
  static String getBiometricTypeName(List<BiometricType> types) {
    if (types.isEmpty) return 'Biometric';
    
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (types.contains(BiometricType.strong)) {
      return 'Biometric';
    } else if (types.contains(BiometricType.weak)) {
      return 'Biometric';
    }
    
    return 'Biometric';
  }
}

enum BiometricStatus {
  available,
  notAvailable,
  notEnrolled,
}
