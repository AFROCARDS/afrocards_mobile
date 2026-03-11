import 'package:flutter/material.dart';

/// Helper pour obtenir des couleurs adaptées au thème actuel
class ThemeColors {
  final BuildContext context;
  late final bool isDark;
  
  ThemeColors(this.context) {
    isDark = Theme.of(context).brightness == Brightness.dark;
  }
  
  // Couleurs de fond
  Color get background => isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
  Color get cardBackground => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get surfaceColor => isDark ? const Color(0xFF2D2D2D) : Colors.white;
  
  // Couleurs de texte
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF2D3436);
  Color get textSecondary => isDark ? Colors.white70 : const Color(0xFF636E72);
  Color get textMuted => isDark ? Colors.white54 : const Color(0xFF9E9E9E);
  
  // Couleurs d'accent (restent les mêmes)
  Color get primary => const Color(0xFFFFB74D);
  Color get secondary => isDark ? const Color(0xFFCE93D8) : const Color(0xFF9C27B0);
  Color get cyan => const Color(0xFF00BCD4);
  Color get pink => const Color(0xFFE91E63);
  Color get green => const Color(0xFF4CAF50);
  Color get red => const Color(0xFFF44336);
  
  // Bordures et dividers
  Color get divider => isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0);
  Color get border => isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0);
  
  // Ombres
  Color get shadowColor => isDark ? Colors.black54 : Colors.black12;
  double get shadowOpacity => isDark ? 0.3 : 0.08;
  
  // Icons
  Color get iconColor => isDark ? Colors.white70 : const Color(0xFF636E72);
  Color get iconActive => primary;
  
  // Overlay pour les images de fond en dark mode
  ColorFilter? get backgroundOverlay => isDark 
    ? ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken)
    : null;
    
  // Box decoration pour les cartes
  BoxDecoration cardDecoration({double radius = 16}) => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(shadowOpacity),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Decoration pour le fond avec image
  BoxDecoration backgroundDecoration(String imagePath) => BoxDecoration(
    image: DecorationImage(
      image: AssetImage(imagePath),
      fit: BoxFit.cover,
      colorFilter: backgroundOverlay,
    ),
  );
  
  // Text styles
  TextStyle get titleStyle => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
  
  TextStyle get subtitleStyle => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  
  TextStyle get bodyStyle => TextStyle(
    fontSize: 14,
    color: textSecondary,
  );
  
  TextStyle get captionStyle => TextStyle(
    fontSize: 12,
    color: textMuted,
  );
}

/// Extension pour accéder facilement aux couleurs du thème
extension ThemeColorsExtension on BuildContext {
  ThemeColors get colors => ThemeColors(this);
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
