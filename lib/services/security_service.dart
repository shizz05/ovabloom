import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _passcodeKey = 'app_passcode';

  /// Checks if a passcode has been set.
  Future<bool> hasPasscode() async {
    final passcode = await _secureStorage.read(key: _passcodeKey);
    return passcode != null && passcode.isNotEmpty;
  }

  /// Verifies if the provided passcode matches the stored one.
  Future<bool> verifyPasscode(String passcode) async {
    final storedPasscode = await _secureStorage.read(key: _passcodeKey);
    return storedPasscode == passcode;
  }

  /// Saves the passcode securely.
  Future<void> setPasscode(String passcode) async {
    await _secureStorage.write(key: _passcodeKey, value: passcode);
  }

  /// Deletes the stored passcode.
  Future<void> deletePasscode() async {
    await _secureStorage.delete(key: _passcodeKey);
  }

  /// Checks if biometric authentication is available on the device.
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print("Error checking biometrics: $e");
      return false;
    }
  }

  /// Triggers the biometric authentication prompt.
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock OvaBloom to continue',
        options: const AuthenticationOptions(
          biometricOnly: true, // Use only biometrics, no device PIN
          stickyAuth: true, // Keep the auth prompt active
        ),
      );
    } on PlatformException catch (e) {
      print("Error during biometric authentication: $e");
      return false;
    }
  }
}
