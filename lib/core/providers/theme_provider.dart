import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider pour gérer le thème (Dark/Light mode)
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _loadTheme();
  }

  /// Charger le thème depuis les préférences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement thème: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Basculer entre dark et light mode
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _saveTheme();
  }

  /// Définir le thème
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      await _saveTheme();
    }
  }

  /// Sauvegarder le thème dans les préférences
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);
    } catch (e) {
      debugPrint('Erreur sauvegarde thème: $e');
    }
  }

  /// Thème clair
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.orange,
    primaryColor: const Color(0xFFFFB74D),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE0E0E0),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF2D3436),
      elevation: 0,
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFFB74D),
      secondary: Color(0xFF9C27B0),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF2D3436),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF2D3436)),
      bodyMedium: TextStyle(color: Color(0xFF2D3436)),
      titleLarge: TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.bold),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF636E72)),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFFFFB74D),
      unselectedItemColor: Color(0xFF636E72),
    ),
  );

  /// Thème sombre
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.orange,
    primaryColor: const Color(0xFFFFB74D),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: const Color(0xFF2D2D2D),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFFB74D),
      secondary: Color(0xFFCE93D8),
      surface: Color(0xFF1E1E1E),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    iconTheme: const IconThemeData(color: Colors.white70),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: Color(0xFFFFB74D),
      unselectedItemColor: Colors.white54,
    ),
  );
}
