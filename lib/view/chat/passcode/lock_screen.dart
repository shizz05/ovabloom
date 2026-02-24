import 'package:flutter/material.dart';
import 'package:pcos_app/providers/app_lock_provider.dart';
import 'package:pcos_app/services/security_service.dart';
import 'package:pcos_app/view/chat/passcode/passcode_widgets.dart'; // Import shared widgets
import 'package:provider/provider.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;

  const LockScreen({super.key, required this.onUnlock});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final SecurityService _securityService = SecurityService();
  String _enteredPasscode = '';
  String _feedbackMessage = '';
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricsAndAuthenticate();
  }

  Future<void> _checkBiometricsAndAuthenticate() async {
    final isAvailable = await _securityService.isBiometricAvailable();
    setState(() {
      _isBiometricAvailable = isAvailable;
    });

    if (mounted) {
      final appLockProvider =
          Provider.of<AppLockProvider>(context, listen: false);
      if (isAvailable && appLockProvider.isBiometricEnabled) {
        _authenticateWithBiometrics();
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    final didAuthenticate = await _securityService.authenticateWithBiometrics();
    if (didAuthenticate) {
      widget.onUnlock();
    }
  }

  void _onNumberPressed(String number) {
    if (_enteredPasscode.length < 4) {
      setState(() {
        _enteredPasscode += number;
        _feedbackMessage = '';
      });

      if (_enteredPasscode.length == 4) {
        _verifyPasscode();
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPasscode.isNotEmpty) {
      setState(() {
        _enteredPasscode =
            _enteredPasscode.substring(0, _enteredPasscode.length - 1);
      });
    }
  }

  Future<void> _verifyPasscode() async {
    final isValid = await _securityService.verifyPasscode(_enteredPasscode);
    if (isValid) {
      widget.onUnlock();
    } else {
      setState(() {
        _enteredPasscode = '';
        _feedbackMessage = 'Incorrect Passcode. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(Icons.lock_person_rounded,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text('Enter Passcode', style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            PasscodeIndicator(
                passcodeLength: _enteredPasscode.length), // Use shared widget
            const SizedBox(height: 24),
            Text(
              _feedbackMessage,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
            ),
            const Spacer(),
            NumericKeypad(
              // Use shared widget
              onNumberPressed: _onNumberPressed,
              onDeletePressed: _onDeletePressed,
            ),
            if (_isBiometricAvailable)
              TextButton.icon(
                onPressed: _authenticateWithBiometrics,
                icon: Icon(Icons.fingerprint, color: theme.colorScheme.primary),
                label: Text('Use Biometrics',
                    style: TextStyle(color: theme.colorScheme.primary)),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
