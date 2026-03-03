import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/user_state_provider.dart';
import 'challenge_matching_screen.dart';

/// Écran de sélection du nombre de questions pour le mode Challenge
/// Conforme à la maquette: 10, 15, 20 questions avec bouton Valider
class ChallengeQuestionCountScreen extends StatefulWidget {
  final String? token;

  const ChallengeQuestionCountScreen({
    super.key,
    this.token,
  });

  @override
  State<ChallengeQuestionCountScreen> createState() =>
      _ChallengeQuestionCountScreenState();
}

class _ChallengeQuestionCountScreenState
    extends State<ChallengeQuestionCountScreen> {
  int _selectedCount = 10;

  final List<int> _questionCounts = [10, 15, 20];

  void _onValidate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeMatchingScreen(
          questionCount: _selectedCount,
          token: widget.token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Titre
                    const Text(
                      'Definissez le nombre de questions\nqui vous convient',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Options de nombre de questions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _questionCounts.map((count) {
                        final isSelected = _selectedCount == count;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedCount = count),
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFF5F0FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF6B4EAA)
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF6B4EAA)
                                              .withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? const Color(0xFF6B4EAA)
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),

                    // Bouton Valider
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: _onValidate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8E4A8),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Valider',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lien retour menu principal
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Retour au menu principal',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Consumer<UserStateProvider>(
      builder: (context, userState, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar utilisateur
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: userState.avatarUrl != null
                        ? NetworkImage(userState.avatarUrl!)
                        : null,
                    child: userState.avatarUrl == null
                        ? const Icon(Icons.person, color: Colors.white, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 10),

                  // Nom et niveau
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userState.userName.isNotEmpty ? userState.userName : 'Joueur',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userState.userLevel,
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
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
                  const SizedBox(width: 8),

                  // Stats: Coins
                  _buildStatBadge(
                    icon: Icons.monetization_on,
                    value: userState.coins.toString(),
                    color: Colors.orange,
                    bgColor: Colors.orange.shade50,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Titre avec bouton retour
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Mode Challenge',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
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
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, color: color, size: 14),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: const Color(0xFF6B4EAA),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.style_outlined),
          activeIcon: Icon(Icons.style),
          label: 'Mes Cartes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag),
          label: 'Boutiques',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}
