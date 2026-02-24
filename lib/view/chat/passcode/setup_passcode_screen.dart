import 'package:flutter/material.dart';
import 'package:pcos_app/providers/app_lock_provider.dart';
import 'package:pcos_app/services/security_service.dart';
import 'package:pcos_app/view/chat/passcode/passcode_widgets.dart'; // Import shared widgets
import 'package:provider/provider.dart';

class SetupPasscodeScreen extends StatefulWidget {
  const SetupPasscodeScreen({super.key});

  @override
  State<SetupPasscodeScreen> createState() => _SetupPasscodeScreenState();
}

class _SetupPasscodeScreenState extends State<SetupPasscodeScreen> {
  String _enteredPasscode = '';
  String _firstPasscode = '';
  bool _isConfirming = false;
  String _feedbackMessage = '';

  void _onNumberPressed(String number) {
    if (_enteredPasscode.length < 4) {
      setState(() {
        _enteredPasscode += number;
        _feedbackMessage = ''; // Clear feedback on new input
      });

      if (_enteredPasscode.length == 4) {
        _processPasscode();
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPasscode.isNotEmpty) {
      setState(() {
        _enteredPasscode =
            _enteredPasscode.substring(0, _enteredPasscode.length - 1);
        _feedbackMessage = ''; // Clear feedback
      });
    }
  }

  void _processPasscode() {
    if (!_isConfirming) {
      // First entry done, move to confirmation
      setState(() {
        _firstPasscode = _enteredPasscode;
        _enteredPasscode = '';
        _isConfirming = true;
      });
    } else {
      // Confirmation entry done, check for match
      if (_enteredPasscode == _firstPasscode) {
        _savePasscodeAndEnableLock();
      } else {
        // Mismatch, reset and show error
        setState(() {
          _feedbackMessage = 'Passcodes do not match. Try again.';
          _enteredPasscode = '';
          _firstPasscode = '';
          _isConfirming = false;
        });
      }
    }
  }

  Future<void> _savePasscodeAndEnableLock() async {
    final securityService = SecurityService();
    await securityService.setPasscode(_enteredPasscode);

    if (mounted) {
      Provider.of<AppLockProvider>(context, listen: false).enableAppLock();
      // Navigate back to settings page after a short delay
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passcode set and App Lock enabled.'),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          // Pop twice to get back to the main app lock settings page
          int count = 0;
          Navigator.of(context).popUntil((_) => count++ >= 2);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isConfirming ? 'Confirm Passcode' : 'Set Passcode',
            style: theme.textTheme.titleLarge),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.iconTheme,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              _isConfirming
                  ? 'Re-enter your passcode'
                  : 'Enter a 4-digit passcode',
              style: theme.textTheme.titleMedium,
            ),
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
