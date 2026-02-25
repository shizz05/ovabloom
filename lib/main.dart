import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pcos_app/auth_gate.dart';
import 'package:pcos_app/homepage.dart';
import 'package:pcos_app/profile_settings_page.dart';
import 'package:pcos_app/screens/insight_page.dart';
import 'package:pcos_app/view/chat/help_desk.dart';
import 'package:pcos_app/config/supabase_config.dart';
import 'package:provider/provider.dart';
import 'providers/app_lock_provider.dart';
import 'theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const AppWrapper());
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(AppThemes.sakuraKiss),
        ),
        ChangeNotifierProvider(
          create: (_) => AppLockProvider(),
        ),
      ],
      child: const MyApp(),
    );
  }
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
          home: const AuthGate(),
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
