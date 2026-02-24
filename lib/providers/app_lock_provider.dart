import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockProvider with ChangeNotifier {
  static const String _appLockEnabledKey = 'app_lock_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled'; // New key

  bool _isAppLockEnabled = false;
  bool get isAppLockEnabled => _isAppLockEnabled;

  bool _isBiometricEnabled = false; // New state variable
  bool get isBiometricEnabled => _isBiometricEnabled; // New getter

  AppLockProvider() {
    _loadAppLockState();
  }

  Future<void> _loadAppLockState() async {
    final prefs = await SharedPreferences.getInstance();
    _isAppLockEnabled = prefs.getBool(_appLockEnabledKey) ?? false;
    _isBiometricEnabled =
        prefs.getBool(_biometricEnabledKey) ?? false; // Load biometric state
    notifyListeners();
  }

  Future<void> enableAppLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, true);
    _isAppLockEnabled = true;
    notifyListeners();
  }

  Future<void> disableAppLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabledKey, false);
    _isAppLockEnabled = false;
    // Also disable biometrics when app lock is turned off
    await setBiometricEnabled(false);
    notifyListeners();
  }

  // New method to toggle biometrics
  Future<void> setBiometricEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, isEnabled);
    _isBiometricEnabled = isEnabled;
    notifyListeners();
  }
}
