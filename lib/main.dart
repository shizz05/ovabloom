import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pcos_app/auth_gate.dart';
import 'package:pcos_app/homepage.dart';
import 'package:pcos_app/profile_settings_page.dart';
import 'package:pcos_app/screens/insight_page.dart';
import 'package:pcos_app/view/chat/help_desk.dart';
import 'package:provider/provider.dart';
import 'providers/app_lock_provider.dart';
import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => ThemeProvider(AppThemes.sakuraKiss)),
        ChangeNotifierProvider(create: (_) => AppLockProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.getTheme(),
          home: const AuthGate(), // AuthGate will handle the initial screen
          routes: {
            '/home': (context) => const HomePage(),
            '/insights': (context) => const InsightPage(),
            '/chat': (context) => const HelpDesk(),
            '/profile': (context) => const ProfileSettingsPage(),
          },
        );
      },
    );
  }
}
