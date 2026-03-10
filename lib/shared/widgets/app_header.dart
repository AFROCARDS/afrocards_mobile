import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/user_state_provider.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/home/presentation/screens/boutique_screen.dart';

/// Couleurs du design (identiques à profile_screen)
class _DesignColors {
  static const Color primary = Color(0xFFFFB74D);      // Orange principal
  static const Color secondary = Color(0xFF9C27B0);    // Violet
  static const Color cyan = Color(0xFF00BCD4);         // Cyan
  static const Color green = Color(0xFF4CAF50);        // Vert
  static const Color pink = Color(0xFFE91E63);         // Rose
  static const Color textDark = Color(0xFF2D3436);     // Texte foncé
  static const Color textMuted = Color(0xFF636E72);    // Texte atténué
}

/// Widget réutilisable pour le header de l'application
/// Affiche l'avatar, le nom, le niveau, les vies et les coins
class AppHeader extends StatelessWidget {
  /// Callback optionnel quand on clique sur l'avatar
  final VoidCallback? onAvatarTap;
  
  /// Afficher un titre avec bouton retour (optionnel)
  final String? title;
  
  /// Callback pour le bouton retour
  final VoidCallback? onBackTap;
  
  /// Actions supplémentaires à afficher (boutons, icons, etc.)
  final List<Widget>? actions;
  
  /// Centrer le titre
  final bool centerTitle;
  
  /// Afficher les stats (vies, coins) - par défaut true sauf si titre
  final bool? showStats;
  
  /// Mode compact (juste le titre sans avatar)
  final bool compactMode;

  const AppHeader({
    super.key,
    this.onAvatarTap,
    this.title,
    this.onBackTap,
    this.actions,
    this.centerTitle = false,
    this.showStats,
    this.compactMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStateProvider>(
      builder: (context, userState, child) {
        final displayStats = showStats ?? (title == null);
        
        // Mode compact: juste le titre
        if (compactMode && title != null) {
          return _buildCompactHeader(context, userState);
        }
        
        // Mode avec titre uniquement
        if (title != null) {
          return _buildTitleHeader(context, userState, displayStats);
        }
        
        // Mode complet avec avatar et stats
        return _buildFullHeader(context, userState);
      },
    );
  }

  Widget _buildCompactHeader(BuildContext context, UserStateProvider userState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton retour
          GestureDetector(
            onTap: onBackTap ?? () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20, color: _DesignColors.textDark),
            ),
          ),
          
          if (centerTitle) const Spacer(),
          
          if (!centerTitle) const SizedBox(width: 16),
          
          // Titre
          if (centerTitle)
            Text(
              title!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _DesignColors.textDark,
              ),
            )
          else
            Expanded(
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _DesignColors.textDark,
                ),
              ),
            ),
          
          if (centerTitle) const Spacer(),
          
          // Actions
          if (actions != null) ...actions!,
          
          // Placeholder pour équilibrer si centerTitle et pas d'actions
          if (centerTitle && (actions == null || actions!.isEmpty))
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTitleHeader(BuildContext context, UserStateProvider userState, bool displayStats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ligne principale avec avatar, nom et stats
          if (displayStats) ...[
            Row(
              children: [
                // Avatar avec bordure gradient
                _buildAvatarWithBorder(context, userState),
                const SizedBox(width: 12),
                
                // Nom et niveau
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userState.userName.isNotEmpty ? userState.userName : 'Joueur',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _DesignColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _DesignColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _DesignColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          userState.userLevel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _DesignColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Stats
                _buildStatBadge(
                  context: context,
                  icon: Icons.favorite,
                  value: '${userState.lives}/${userState.maxLives}',
                  color: _DesignColors.pink,
                  showPlus: true,
                ),
                const SizedBox(width: 8),
                _buildStatBadge(
                  context: context,
                  icon: Icons.monetization_on,
                  value: _formatNumber(userState.coins),
                  color: _DesignColors.primary,
                  showPlus: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // Ligne titre
          Row(
            children: [
              // Bouton retour stylé
              GestureDetector(
                onTap: onBackTap ?? () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: _DesignColors.textDark,
                    size: 20,
                  ),
                ),
              ),
              
              if (centerTitle) const Spacer(),
              
              if (!centerTitle) const SizedBox(width: 16),
              
              // Titre
              if (centerTitle)
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _DesignColors.textDark,
                  ),
                )
              else
                Expanded(
                  child: Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _DesignColors.textDark,
                    ),
                  ),
                ),
              
              if (centerTitle) const Spacer(),
              
              // Actions
              if (actions != null) ...actions!,
              
              // Placeholder si centerTitle sans actions
              if (centerTitle && (actions == null || actions!.isEmpty))
                const SizedBox(width: 44),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullHeader(BuildContext context, UserStateProvider userState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar avec bordure gradient
          _buildAvatarWithBorder(context, userState),
          const SizedBox(width: 14),
          
          // Nom et niveau
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userState.userName.isNotEmpty ? userState.userName : 'Joueur',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _DesignColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Badge niveau
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _DesignColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _DesignColors.secondary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        userState.userLevel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _DesignColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge XP
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _DesignColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _DesignColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, color: _DesignColors.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${userState.pointsXP} XP',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _DesignColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Stats avec style amélioré
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatBadge(
                context: context,
                icon: Icons.favorite,
                value: '${userState.lives}/${userState.maxLives}',
                color: _DesignColors.pink,
                showPlus: true,
              ),
              const SizedBox(height: 6),
              _buildStatBadge(
                context: context,
                icon: Icons.monetization_on,
                value: _formatNumber(userState.coins),
                color: _DesignColors.primary,
                showPlus: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWithBorder(BuildContext context, UserStateProvider userState) {
    return GestureDetector(
      onTap: onAvatarTap ?? () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [_DesignColors.primary, _DesignColors.pink, _DesignColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _DesignColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.white, width: 2),
            image: userState.avatarUrl != null && userState.avatarUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(userState.avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: userState.avatarUrl == null || userState.avatarUrl!.isEmpty
              ? Icon(Icons.person, color: Colors.grey.shade400, size: 26)
              : null,
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required BuildContext context,
    required IconData icon,
    required String value,
    required Color color,
    bool showPlus = false,
  }) {
    return GestureDetector(
      onTap: showPlus ? () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const BoutiqueScreen()),
        );
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showPlus) ...[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 6),
            ],
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
