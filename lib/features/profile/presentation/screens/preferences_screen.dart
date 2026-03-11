import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/theme_colors.dart';

/// Écran des préférences de l'application
class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final colors = context.colors;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(colors.backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context, isDark),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Apparence
                        _buildSectionTitle('Apparence', isDark),
                        const SizedBox(height: 12),
                        _buildThemeSelector(context, themeProvider, isDark),
                        
                        const SizedBox(height: 32),
                        
                        // Section Notifications (placeholder pour futures fonctionnalités)
                        _buildSectionTitle('Autres préférences', isDark),
                        const SizedBox(height: 12),
                        _buildComingSoonCard(isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDark ? Colors.white : const Color(0xFF2D3436),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Préférences',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF2D3436),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : const Color(0xFF636E72),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeProvider themeProvider, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Option Light Mode
          _buildThemeOption(
            context: context,
            themeProvider: themeProvider,
            isDark: isDark,
            isLightOption: true,
            isSelected: !themeProvider.isDarkMode,
          ),
          
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0),
          ),
          
          // Option Dark Mode
          _buildThemeOption(
            context: context,
            themeProvider: themeProvider,
            isDark: isDark,
            isLightOption: false,
            isSelected: themeProvider.isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeProvider themeProvider,
    required bool isDark,
    required bool isLightOption,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        themeProvider.setThemeMode(isLightOption ? ThemeMode.light : ThemeMode.dark);
      },
      borderRadius: BorderRadius.vertical(
        top: isLightOption ? const Radius.circular(16) : Radius.zero,
        bottom: !isLightOption ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLightOption
                    ? [const Color(0xFFFFB74D), const Color(0xFFFF8A65)]
                    : [const Color(0xFF5C6BC0), const Color(0xFF3949AB)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isLightOption ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLightOption ? 'Mode Clair' : 'Mode Sombre',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLightOption 
                      ? 'Interface lumineuse et colorée'
                      : 'Interface sombre pour vos yeux',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : const Color(0xFF636E72),
                    ),
                  ),
                ],
              ),
            ),
            
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected 
                    ? const Color(0xFFFFB74D)
                    : (isDark ? Colors.white30 : const Color(0xFFBDBDBD)),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFFFFB74D) : Colors.transparent,
              ),
              child: isSelected 
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white10 : const Color(0xFFF5F5F5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.upcoming,
              color: isDark ? Colors.white54 : const Color(0xFF9E9E9E),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'D\'autres préférences seront bientôt disponibles...',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : const Color(0xFF9E9E9E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
