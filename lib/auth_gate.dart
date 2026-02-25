import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pcos_app/homepage.dart';
import 'package:pcos_app/logo_page.dart';
import 'package:pcos_app/providers/app_lock_provider.dart';
import 'package:pcos_app/signup_page.dart';
import 'package:pcos_app/view/chat/passcode/lock_screen.dart';
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

    // Splash delay
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
    final supabase = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Determine destination based on live Supabase auth state
        final session = snapshot.data?.session;
        final Widget destination =
            session != null ? const HomePage() : const SignupPage();

        // If app lock disabled OR already unlocked → go to destination
        if (!appLockProvider.isAppLockEnabled || _isUnlocked) {
          return destination;
        }

        // Otherwise show lock screen
        return LockScreen(
          onUnlock: () {
            setState(() {
              _isUnlocked = true;
            });
          },
        );
      },
    );
  }
}
