import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pcos_app/homepage.dart';
import 'package:pcos_app/logo_page.dart';
import 'package:pcos_app/providers/app_lock_provider.dart';
import 'package:pcos_app/signup_page.dart';
import 'package:pcos_app/view/chat/passcode/lock_screen.dart'; // Corrected import path
import 'package:provider/provider.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isUnlocked = false;
  bool _showLogo = true;

  @override
  void initState() {
    super.initState();
    // Wait for a few seconds and then hide the logo
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showLogo = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLogo) {
      return const LogoPage();
    }

    final appLockProvider = context.watch<AppLockProvider>();
    final user = FirebaseAuth.instance.currentUser;

    // Determine the correct destination page based on Firebase auth status
    final Widget destination =
        user != null ? const HomePage() : const SignupPage();

    // If app lock is disabled, or if the user has already unlocked, go to the destination
    if (!appLockProvider.isAppLockEnabled || _isUnlocked) {
      return destination;
    }

    // Otherwise, show the lock screen, which will lead to the destination upon success
    return LockScreen(
      onUnlock: () {
        setState(() {
          _isUnlocked = true;
        });
      },
    );
  }
}
