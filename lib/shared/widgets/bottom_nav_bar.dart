import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/user_state_provider.dart';
import '../../features/home/presentation/screens/card_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

/// Widget réutilisable pour la barre de navigation inférieure
class AppBottomNavBar extends StatelessWidget {
  /// Index de l'onglet actuellement sélectionné
  final int currentIndex;
  
  /// Callback quand un onglet est sélectionné
  final ValueChanged<int>? onTap;

  const AppBottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        currentIndex: currentIndex,
        onTap: (index) {
          if (onTap != null) {
            onTap!(index);
          } else {
            // Navigation centralisée avec Provider
            final userState = context.read<UserStateProvider>();
            switch (index) {
              case 0:
                // Accueil
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HomeScreen(
                    userName: userState.userName,
                    userLevel: userState.userLevel,
                    userPoints: userState.pointsXP,
                    userLives: userState.lives,
                    avatarUrl: userState.avatarUrl,
                    token: userState.token,
                  )),
                  (route) => false,
                );
                break;
              case 1:
                // Mes Cartes
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => CardScreen(
                    userName: userState.userName,
                    userLevel: userState.userLevel,
                    userPoints: userState.pointsXP,
                    userLives: userState.lives,
                    avatarUrl: userState.avatarUrl,
                    token: userState.token,
                  )),
                  (route) => false,
                );
                break;
              // Les autres onglets peuvent être personnalisés ici
            }
          }
        },
        selectedFontSize: 12,
        unselectedFontSize: 12,
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
      ),
    );
  }
}
