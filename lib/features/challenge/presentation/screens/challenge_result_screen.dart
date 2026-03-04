import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/user_state_provider.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../classement/presentation/screens/classement_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';

/// Écran de résultat du Challenge avec animation de félicitations
/// Affiche le vainqueur et les statistiques
class ChallengeResultScreen extends StatefulWidget {
  final String? userName;
  final String? token;
  final int playerScore;
  final int opponentScore;
  final int totalQuestions;
  final String? opponentName;
  final int xpGained;
  final int coinsGained;
  final bool isWinner;

  const ChallengeResultScreen({
    super.key,
    this.userName,
    this.token,
    required this.playerScore,
    required this.opponentScore,
    required this.totalQuestions,
    this.opponentName,
    this.xpGained = 0,
    this.coinsGained = 0,
    required this.isWinner,
  });

  @override
  State<ChallengeResultScreen> createState() => _ChallengeResultScreenState();
}

class _ChallengeResultScreenState extends State<ChallengeResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _scaleController.forward();

    // Mettre à jour les stats utilisateur
    _updateUserStats();
  }

  void _updateUserStats() {
    final userState = context.read<UserStateProvider>();
    userState.addXP(widget.xpGained);
    userState.addCoins(widget.coinsGained);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _goToClassement() {
    final userState = context.read<UserStateProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassementScreen(
          userName: userState.userName,
          userLevel: userState.userLevel,
          userLives: userState.lives,
          userCoins: userState.coins,
          avatarUrl: userState.avatarUrl,
          token: widget.token,
        ),
      ),
    );
  }

  void _continuer() {
    final userState = context.read<UserStateProvider>();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          userName: userState.userName,
          userLevel: userState.userLevel,
          userPoints: userState.coins,
          userLives: userState.lives,
          avatarUrl: userState.avatarUrl,
          token: widget.token,
        ),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/backgrounds/img.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const AppHeader(centerTitle: true,),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(
        currentIndex: 0,
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cercle animé avec décorations
          ScaleTransition(
            scale: _scaleAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Décorations autour du cercle
                ..._buildDecorations(),

                // Cercle principal (gris simple comme dans la maquette)
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Titre
          Text(
            widget.isWinner ? 'Felicitation!!!' : 'Dommage...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Message de résultat
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.isWinner
                  ? 'Tu as brillamment remporté ce challenge contre ${widget.opponentName ?? 'ton adversaire'} avec un score de ${widget.playerScore}/${widget.totalQuestions}. Continue sur cette lancée, tu es sur la bonne voie pour devenir un champion !'
                  : '${widget.opponentName ?? 'Ton adversaire'} l\'a emporté cette fois avec ${widget.opponentScore}/${widget.totalQuestions}. Ne te décourage pas, chaque défi est une occasion d\'apprendre. Retente ta chance !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Bouton Voir Classement
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: _goToClassement,
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
                'Voir Classement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bouton Continuer
          TextButton(
            onPressed: _continuer,
            child: Text(
              'Continuer',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDecorations() {
    // Petites décorations autour du cercle (points, x, +) selon la maquette
    return [
      // Point bleu en haut
      Positioned(
        top: 0,
        left: 80,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
          ),
        ),
      ),
      // + en haut gauche
      const Positioned(
        top: 30,
        left: 15,
        child: Text('+', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w300)),
      ),
      // x en haut droite
      const Positioned(
        top: 20,
        right: 20,
        child: Text('×', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w300)),
      ),
      // x à gauche
      const Positioned(
        top: 90,
        left: 10,
        child: Text('×', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w300)),
      ),
      // + à droite
      const Positioned(
        top: 100,
        right: 15,
        child: Text('+', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w300)),
      ),
      // Point rose en bas
      Positioned(
        bottom: 10,
        left: 85,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.pink,
          ),
        ),
      ),
    ];
  }

  Widget _buildGainBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}