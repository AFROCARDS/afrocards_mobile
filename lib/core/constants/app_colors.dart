import 'package:flutter/material.dart';

/// 🎨 COULEURS DE L'APPLICATION AFROCARDS
/// Basées sur la charte graphique et les maquettes

class AppColors {
  // ========================================
  // 🎯 COULEURS PRINCIPALES
  // ========================================

  /// Couleur primaire - Indigo (Buttons, Headers)
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  /// Couleur secondaire - Amber (Accents, Coins)
  static const Color secondary = Color(0xFFF59E0B);
  static const Color secondaryLight = Color(0xFFFBBF24);
  static const Color secondaryDark = Color(0xFFD97706);

  /// Couleur d'accent - Vert (Success, Correct Answer)
  static const Color accent = Color(0xFF10B981);
  static const Color accentLight = Color(0xFF34D399);
  static const Color accentDark = Color(0xFF059669);

  // ========================================
  // 🖼️ COULEURS DE FOND
  // ========================================

  static const Color background = Color(0xFFF9FAFB);
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1F2937);

  // ========================================
  // 📝 COULEURS DE TEXTE
  // ========================================

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;

  // ========================================
  // 🎮 COULEURS DE GAMEPLAY
  // ========================================

  /// Réponse correcte
  static const Color correctAnswer = Color(0xFF10B981);
  static const Color correctAnswerLight = Color(0xFFD1FAE5);

  /// Réponse incorrecte
  static const Color wrongAnswer = Color(0xFFEF4444);
  static const Color wrongAnswerLight = Color(0xFFFEE2E2);

  /// Coins/Monnaie
  static const Color coin = Color(0xFFFBBF24);
  static const Color coinGradientStart = Color(0xFFFBBF24);
  static const Color coinGradientEnd = Color(0xFFF59E0B);

  /// Points de Vie
  static const Color vie = Color(0xFFEF4444);
  static const Color vieGradientStart = Color(0xFFFCA5A5);
  static const Color vieGradientEnd = Color(0xFFEF4444);

  /// XP / Progression
  static const Color xp = Color(0xFF8B5CF6);
  static const Color xpLight = Color(0xFFDDD6FE);

  // ========================================
  // ⚠️ COULEURS D'ÉTAT
  // ========================================

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ========================================
  // 🏆 COULEURS DE CLASSEMENT
  // ========================================

  /// Or (1ère place)
  static const Color gold = Color(0xFFFFD700);

  /// Argent (2ème place)
  static const Color silver = Color(0xFFC0C0C0);

  /// Bronze (3ème place)
  static const Color bronze = Color(0xFFCD7F32);

  // ========================================
  // 🎨 COULEURS DE DIFFICULTÉ
  // ========================================

  static const Color difficultyEasy = Color(0xFF10B981);    // Vert
  static const Color difficultyMedium = Color(0xFFF59E0B);  // Orange
  static const Color difficultyHard = Color(0xFFEF4444);    // Rouge
  static const Color difficultyExpert = Color(0xFF8B5CF6);  // Violet

  // ========================================
  // 🌈 DÉGRADÉS
  // ========================================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coinGradient = LinearGradient(
    colors: [coinGradientStart, coinGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient vieGradient = LinearGradient(
    colors: [vieGradientStart, vieGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========================================
  // 🎯 HELPERS
  // ========================================

  /// Retourne la couleur selon la difficulté
  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facile':
        return difficultyEasy;
      case 'moyen':
        return difficultyMedium;
      case 'difficile':
        return difficultyHard;
      case 'expert':
        return difficultyExpert;
      default:
        return difficultyMedium;
    }
  }

  /// Retourne la couleur selon le rang
  static Color getRankColor(int rank) {
    switch (rank) {
      case 1:
        return gold;
      case 2:
        return silver;
      case 3:
        return bronze;
      default:
        return textSecondary;
    }
  }
}