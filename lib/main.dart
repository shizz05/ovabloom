import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'logo_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 🔥 REQUIRED
  await Firebase.initializeApp(); // 🔥 REQUIRED
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LogoPage(), // 🔁 SAME AS BEFORE
    );
  }
}
