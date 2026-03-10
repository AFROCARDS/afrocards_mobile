import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/user_state_provider.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

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

  const AppHeader({
    super.key,
    this.onAvatarTap,
    this.title,
    this.onBackTap,
    this.actions,
    bool centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserStateProvider>(
      builder: (context, userState, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Avatar et info utilisateur
                  GestureDetector(
                    onTap: onAvatarTap ?? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: userState.avatarUrl != null
                          ? NetworkImage(userState.avatarUrl!)
                          : null,
                      child: userState.avatarUrl == null
                          ? const Icon(Icons.person, color: Colors.white, size: 30)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userState.userName.isNotEmpty ? userState.userName : 'Joueur',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userState.userLevel,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Stats: Vies
                  _buildStatBadge(
                    icon: Icons.favorite,
                    value: '${userState.lives.toString().padLeft(2, '0')}/${userState.maxLives.toString().padLeft(2, '0')}',
                    color: Colors.red,
                    bgColor: Colors.red.shade50,
                  ),
                  const SizedBox(width: 10),
                  // Stats: Coins
                  _buildStatBadge(
                    icon: Icons.monetization_on,
                    value: userState.coins.toString(),
                    color: Colors.orange,
                    bgColor: Colors.orange.shade50,
                  ),
                ],
              ),
              // Titre avec bouton retour (optionnel)
              if (title != null) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (onBackTap != null)
                      GestureDetector(
                        onTap: onBackTap,
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 24,
                        ),
                      ),
                    if (onBackTap != null) const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (actions != null) ...actions!,
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, color: color, size: 16),
        ],
      ),
    );
  }
}
