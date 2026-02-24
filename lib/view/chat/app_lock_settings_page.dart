import 'package:flutter/material.dart';
import 'package:pcos_app/providers/app_lock_provider.dart';
import 'package:pcos_app/services/security_service.dart';
import 'package:pcos_app/view/chat/passcode/setup_passcode_screen.dart';
import 'package:provider/provider.dart';

class AppLockSettingsPage extends StatefulWidget {
  const AppLockSettingsPage({super.key});

  @override
  State<AppLockSettingsPage> createState() => _AppLockSettingsPageState();
}

class _AppLockSettingsPageState extends State<AppLockSettingsPage> {
  final SecurityService _securityService = SecurityService();
  bool _hasPasscode = false;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkPasscodeAndBiometrics();
  }

  Future<void> _checkPasscodeAndBiometrics() async {
    final hasPasscode = await _securityService.hasPasscode();
    final isBiometricAvailable = await _securityService.isBiometricAvailable();
    if (mounted) {
      setState(() {
        _hasPasscode = hasPasscode;
        _isBiometricAvailable = isBiometricAvailable;
      });
    }
  }

  void _navigateToSetupPasscode() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SetupPasscodeScreen()),
    ).then((_) {
      _checkPasscodeAndBiometrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Listen to the provider for UI updates
    final appLockProvider = Provider.of<AppLockProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('App Lock Settings', style: theme.textTheme.titleLarge),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.iconTheme,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: Text('Enable App Lock', style: theme.textTheme.bodyLarge),
            value: appLockProvider.isAppLockEnabled,
            onChanged: (bool value) {
              if (value) {
                if (!_hasPasscode) {
                  _navigateToSetupPasscode();
                } else {
                  appLockProvider.enableAppLock();
                }
              } else {
                // Use the provider to disable
                appLockProvider.disableAppLock();
              }
            },
            secondary:
                Icon(Icons.lock_outline, color: theme.colorScheme.primary),
          ),
          const Divider(),
          if (appLockProvider.isAppLockEnabled) ...[
            ListTile(
              title: Text(_hasPasscode ? 'Change Passcode' : 'Set Passcode',
                  style: theme.textTheme.bodyLarge),
              leading: Icon(Icons.password, color: theme.colorScheme.primary),
              onTap: _navigateToSetupPasscode,
            ),
            if (_isBiometricAvailable) ...[
              const Divider(),
              SwitchListTile(
                title: Text('Enable Biometric Authentication',
                    style: theme.textTheme.bodyLarge),
                // The value now comes from the provider
                value: appLockProvider.isBiometricEnabled,
                onChanged: (bool value) {
                  // The onChanged now calls the provider method
                  appLockProvider.setBiometricEnabled(value);
                },
                secondary:
                    Icon(Icons.fingerprint, color: theme.colorScheme.primary),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
