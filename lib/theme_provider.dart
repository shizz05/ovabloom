import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData;

  ThemeProvider(this._themeData);

  ThemeData getTheme() => _themeData;

  void setTheme(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }
}

class AppThemes {
  static final ThemeData sakuraKiss = ThemeData(
    primaryColor: const Color(0xFF9E4A69),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF9E4A69),
      secondary: Color(0xFFC67C96),
      surface: Color(0xFFE8C8D9),
      background: Color(0xFFCBD8EC),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF9E4A69),
      onBackground: Color(0xFF9E4A69),
    ),
    scaffoldBackgroundColor: const Color(0xFFCBD8EC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF9E4A69),
      foregroundColor: Colors.white,
    ),
    cardColor: const Color(0xFFE8C8D9),
    iconTheme: const IconThemeData(color: Color(0xFF9E4A69)),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF9E4A69)),
      bodyMedium: TextStyle(color: Color(0xFFC67C96)),
      titleLarge:
          TextStyle(color: Color(0xFF9E4A69), fontWeight: FontWeight.bold),
    ),
  );

  static final ThemeData violetBreeze = ThemeData(
    primaryColor: const Color(0xFF9A84D1),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF9A84D1),
      secondary: Color(0xFFD5B8E1),
      surface: Color(0xFFF3F1EE),
      background: Color(0xFFA7C59C),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Color(0xFF3B5E3D),
      onBackground: Color(0xFF3B5E3D),
    ),
    scaffoldBackgroundColor: const Color(0xFFF3F1EE),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF9A84D1),
      foregroundColor: Colors.white,
    ),
    cardColor: Colors.white,
    iconTheme: const IconThemeData(color: Color(0xFF3B5E3D)),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF3B5E3D)),
      bodyMedium: TextStyle(color: Color(0xFF9A84D1)),
      titleLarge:
          TextStyle(color: Color(0xFF3B5E3D), fontWeight: FontWeight.bold),
    ),
  );

  static final ThemeData blushPetal = ThemeData(
    primaryColor: const Color(0xFF8B263E),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF8B263E),
      secondary: Color(0xFFD17484),
      surface: Color(0xFFE0AEBA),
      background: Color(0xFF292800),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF8B263E),
      onBackground: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFE0AEBA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF8B263E),
      foregroundColor: Colors.white,
    ),
    cardColor: const Color(0xFFF5E6E8),
    iconTheme: const IconThemeData(color: Color(0xFF786825)),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF292800)),
      bodyMedium: TextStyle(color: Color(0xFF8B263E)),
      titleLarge:
          TextStyle(color: Color(0xFF292800), fontWeight: FontWeight.bold),
    ),
  );

  static final ThemeData sunsetPetal = ThemeData(
    primaryColor: const Color(0xFFE4568B),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFE4568B),
      secondary: Color(0xFFF6C94D),
      surface: Color(0xFFF29BB9),
      background: Color(0xFFA7C7E4),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Color(0xFF5D7B3D),
      onBackground: Color(0xFF5D7B3D),
    ),
    scaffoldBackgroundColor: const Color(0xFFA7C7E4),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFE4568B),
      foregroundColor: Colors.white,
    ),
    cardColor: Colors.white,
    iconTheme: const IconThemeData(color: Color(0xFF5D7B3D)),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF5D7B3D)),
      bodyMedium: TextStyle(color: Color(0xFFE4568B)),
      titleLarge:
          TextStyle(color: Color(0xFF5D7B3D), fontWeight: FontWeight.bold),
    ),
  );
}
