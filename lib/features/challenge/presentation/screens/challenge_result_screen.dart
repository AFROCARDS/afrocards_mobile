import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/user_state_provider.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Générer les particules de confetti si victoire
    if (widget.isWinner) {
      _generateConfetti();
      _confettiController.repeat();
    }
    
    _scaleController.forward();

    // Mettre à jour les stats utilisateur
    _updateUserStats();
  }

  void _generateConfetti() {
    final random = Random();
    for (int i = 0; i < 50; i++) {
      _particles.add(_ConfettiParticle(
        x: random.nextDouble(),
        y: random.nextDouble() * -1,
        color: [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
          Colors.pink,
        ][random.nextInt(7)],
        size: random.nextDouble() * 8 + 4,
        speed: random.nextDouble() * 2 + 1,
      ));
    }
  }

  void _updateUserStats() {
    final userState = context.read<UserStateProvider>();
    userState.addXP(widget.xpGained);
    userState.addCoins(widget.coinsGained);
  }

  @override
  void dispose() {
    _confettiController.dispose();
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
          
          // Confetti animation (si victoire)
          if (widget.isWinner)
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiController.value,
                  ),
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Consumer<UserStateProvider>(
      builder: (context, userState, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: userState.avatarUrl != null
                    ? NetworkImage(userState.avatarUrl!)
                    : null,
                child: userState.avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white, size: 22)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userState.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      userState.userLevel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatBadge(
                value: '${userState.lives.toString().padLeft(2, '0')}/${userState.maxLives.toString().padLeft(2, '0')}',
                icon: Icons.favorite,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              _buildStatBadge(
                value: userState.coins.toString(),
                icon: Icons.monetization_on,
                color: Colors.orange,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBadge({
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('+', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
          const SizedBox(width: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 4),
          Icon(icon, color: color, size: 14),
        ],
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
                
                // Cercle principal
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    boxShadow: [
                      BoxShadow(
                        color: widget.isWinner 
                            ? Colors.amber.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: widget.isWinner
                      ? const Icon(Icons.emoji_events, size: 80, color: Colors.amber)
                      : const Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Titre
          Text(
            widget.isWinner ? 'Felicitation!!!' : 'Dommage...',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: widget.isWinner ? Colors.black87 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Message de résultat
          Text(
            widget.isWinner
                ? 'Tu as battu ${widget.opponentName ?? 'ton adversaire'} avec un score de ${widget.playerScore}/${widget.totalQuestions} contre ${widget.opponentScore}/${widget.totalQuestions}. Continue comme ça, tu es sur la bonne voie!'
                : '${widget.opponentName ?? 'Ton adversaire'} a gagné avec ${widget.opponentScore}/${widget.totalQuestions} contre ${widget.playerScore}/${widget.totalQuestions}. Ne te décourage pas, retente ta chance!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),

          if (widget.isWinner) ...[
            const SizedBox(height: 16),
            // Gains
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGainBadge('+${widget.xpGained} XP', Colors.purple),
                const SizedBox(width: 16),
                _buildGainBadge('+${widget.coinsGained} 🪙', Colors.orange),
              ],
            ),
          ],
          
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
    // Petites décorations autour du cercle (points, x, +)
    final decorations = <Widget>[];
    final symbols = ['•', '×', '+', '•', '×', '+'];
    final colors = [Colors.blue, Colors.grey, Colors.grey, Colors.pink, Colors.grey, Colors.grey];
    final angles = [0.0, 0.6, 1.2, 3.14, 3.8, 4.4];
    final distances = [110.0, 115.0, 105.0, 110.0, 115.0, 105.0];

    for (int i = 0; i < symbols.length; i++) {
      final x = cos(angles[i]) * distances[i];
      final y = sin(angles[i]) * distances[i];
      decorations.add(
        Positioned(
          left: 90 + x - 10,
          top: 90 + y - 10,
          child: Text(
            symbols[i],
            style: TextStyle(
              fontSize: symbols[i] == '•' ? 16 : 20,
              color: colors[i],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return decorations;
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

/// Particule de confetti
class _ConfettiParticle {
  double x;
  double y;
  final Color color;
  final double size;
  final double speed;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.speed,
  });
}

/// Painter pour les confettis
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final y = (particle.y + progress * particle.speed * 2) % 1.5 - 0.5;
      final x = particle.x + sin(progress * 10 + particle.x * 10) * 0.02;
      
      final paint = Paint()
        ..color = particle.color.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x * size.width, y * size.height),
          width: particle.size,
          height: particle.size * 1.5,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
