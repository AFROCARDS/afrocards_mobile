import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../stage/presentation/screens/stage_mode_screen.dart';
import '../../../fiesta/presentation/screens/fiesta_mode_screen.dart';
import '../../../challenge/presentation/screens/challenge_question_count_screen.dart';
import '../../../challenge/presentation/screens/sponsored_challenge_list_screen.dart';
import '../../../quiz/presentation/screens/game_screen.dart';
import '../../../classement/presentation/screens/classement_screen.dart';
import 'card_screen.dart';

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

/// Écran principal Home avec le bouton JOUER UN QUIZZ
/// Affiche les modes de jeu et les sections Explorez et Gagnez
class HomeScreen extends StatefulWidget {
  final String userName;
  final String userLevel;
  final int userPoints;
  final int userLives;
  final String? avatarUrl;
  final String? token;
  final List<int>? selectedCategoryIds;

  const HomeScreen({
    super.key,
    required this.userName,
    this.userLevel = 'Stage 1',
    this.userPoints = 0,
    this.userLives = 5,
    this.avatarUrl,
    this.token,
    this.selectedCategoryIds,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _gameModes = [];
  bool _isLoadingModes = true;
  int _currentNavIndex = 0;
  int? _userRank;
  int? _totalPlayers;

  @override
  void initState() {
    super.initState();
    _loadGameModes();
    _loadUserRank();
  }

  /// Charger les modes de jeu depuis l'API
  Future<void> _loadGameModes() async {
    setState(() => _isLoadingModes = true);

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.modes)),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _gameModes = data['data'] ?? [];
          _isLoadingModes = false;
        });
        debugPrint('Modes de jeu chargés: ${_gameModes.length}');
      } else {
        throw Exception('Erreur lors du chargement des modes');
      }
    } catch (e) {
      debugPrint('Erreur modes: $e');
      setState(() {
        _isLoadingModes = false;
        // Données de test en cas d'erreur réseau
        _gameModes = [
          {
            'idMode': 1,
            'nom': 'Stages',
            'description': 'Progressez à travers des niveaux de difficulté croissante',
            'type': 'solo'
          },
          {
            'idMode': 2,
            'nom': 'Fiesta',
            'description': 'Mode festif avec questions aléatoires',
            'type': 'solo'
          },
        ];
      });
    }
  }

  /// Charger le classement de l'utilisateur
  Future<void> _loadUserRank() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.myRank)),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userRank = data['data']?['rang'] ?? 420;
          _totalPlayers = data['data']?['total'] ?? 10000;
        });
      }
    } catch (e) {
      debugPrint('Erreur classement: $e');
      setState(() {
        _userRank = 420;
        _totalPlayers = 10000;
      });
    }
  }

  void _onGameModeSelected(dynamic mode) {
    final modeName = (mode['nom'] ?? '').toString().toLowerCase();

    if (modeName == 'stages' || modeName == 'stage') {
      // Naviguer vers le mode Stage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StageModeScreen(
            userName: widget.userName,
            userLevel: widget.userLevel,
            userPoints: widget.userPoints,
            userLives: widget.userLives,
            avatarUrl: widget.avatarUrl,
            token: widget.token,
          ),
        ),
      );
    } else if (modeName == 'fiesta') {
      // Naviguer vers le mode Fiesta
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FiestaModeScreen(
            userName: widget.userName,
            userLevel: widget.userLevel,
            userPoints: widget.userPoints,
            userLives: widget.userLives,
            avatarUrl: widget.avatarUrl,
            token: widget.token,
          ),
        ),
      );
    } else if (modeName == 'challenge' || modeName == 'challenges') {
      // Naviguer vers le mode Challenge (PvP)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChallengeQuestionCountScreen(
            token: widget.token,
          ),
        ),
      );
    } else {
      // TODO: Naviguer vers les autres modes de jeu
      debugPrint('Mode sélectionné: ${mode['nom']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mode: ${mode['nom']}')),
      );
    }
  }

  void _showModeInfo(dynamic mode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          mode['nom'] ?? 'Mode',
          style: const TextStyle(color: _DesignColors.textDark, fontWeight: FontWeight.bold),
        ),
        content: Text(
          mode['description'] ?? 'Aucune description disponible',
          style: const TextStyle(color: _DesignColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: _DesignColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _startQuiz() {
    final userState = context.read<UserStateProvider>();

    // Vérifier si l'utilisateur a des vies
    if (!userState.hasLives) {
      _showNoLivesDialog();
      return;
    }

    // Lancer le quiz au niveau actuel du stage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          userName: userState.userName,
          userLevel: userState.userLevel,
          userLives: userState.lives,
          userCoins: userState.coins,
          avatarUrl: userState.avatarUrl,
          token: userState.token,
          levelNumber: userState.currentStageLevel,
          mode: 'stage',
          nombreQuestions: 10,
        ),
      ),
    );
  }

  void _showNoLivesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _DesignColors.pink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.heart_broken, color: _DesignColors.pink, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Plus de vies !', style: TextStyle(color: _DesignColors.textDark)),
          ],
        ),
        content: Consumer<UserStateProvider>(
          builder: (context, userState, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tu n\'as plus de vies pour jouer.',
                  style: TextStyle(color: _DesignColors.textMuted),
                ),
                const SizedBox(height: 12),
                Text(
                  'Prochaine vie dans ${userState.secondsUntilNextLife}s',
                  style: const TextStyle(color: _DesignColors.textMuted),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ou achète des vies avec tes pièces !',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Attendre', style: TextStyle(color: _DesignColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _buyLives();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Acheter (50 \ud83e\ude99)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _buyLives() async {
    final userState = context.read<UserStateProvider>();
    if (await userState.buyLives(1, 50)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('+1 vie achetée !'),
            ],
          ),
          backgroundColor: _DesignColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Pas assez de pièces'),
            ],
          ),
          backgroundColor: _DesignColors.pink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _navigateToClassement() {
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
          token: userState.token,
        ),
      ),
    );
  }

  void _navigateToChallenge() {
    final userState = context.read<UserStateProvider>();

    if (!userState.hasLives) {
      _showNoLivesDialog();
      return;
    }

    // Naviguer vers le mode Challenge (PvP)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeQuestionCountScreen(
          token: userState.token,
        ),
      ),
    );
  }

  void _navigateToSponsoredChallenges() {
    final userState = context.read<UserStateProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SponsoredChallengeListScreen(
          token: userState.token,
        ),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    setState(() => _currentNavIndex = index);
    // La navigation est maintenant gérée dans AppBottomNavBar
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(colors.backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                AppHeader(
                  onAvatarTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  }, centerTitle: true,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        _buildQuizButton(),
                        const SizedBox(height: 30),
                        _buildGameModesSection(),
                        const SizedBox(height: 30),
                        _buildExploreSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
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

  Widget _buildQuizButton() {
    return Center(
      child: _QuizBuzzerButton(
        onPressed: _startQuiz,
      ),
    );
  }

  Widget _buildGameModesSection() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Selectionnez le mode de jeu qui vous\nconvient',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: colors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        _isLoadingModes
            ? const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: _DesignColors.primary),
          ),
        )
            : Row(
          children: _gameModes.map((mode) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildGameModeCard(mode),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGameModeCard(dynamic mode) {
    final modeName = (mode['nom'] ?? '').toString().toLowerCase();

    // Définir l'icône et les couleurs selon le mode
    IconData modeIcon;
    Color modeColor;

    if (modeName == 'stages' || modeName == 'stage') {
      modeIcon = Icons.stairs_rounded;
      modeColor = _DesignColors.primary;
    } else if (modeName == 'fiesta') {
      modeIcon = Icons.celebration_rounded;
      modeColor = _DesignColors.pink;
    } else {
      modeIcon = Icons.gamepad_rounded;
      modeColor = _DesignColors.secondary;
    }

    return GestureDetector(
      onTap: () => _onGameModeSelected(mode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Info button en haut à droite
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => _showModeInfo(mode),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Icône avec fond coloré (style profile_screen)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: modeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(modeIcon, size: 36, color: modeColor),
            ),
            const SizedBox(height: 16),
            Text(
              mode['nom'] ?? 'Mode',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Bouton Jouer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    modeColor.withOpacity(0.2),
                    modeColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: modeColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, size: 16, color: modeColor),
                  const SizedBox(width: 4),
                  Text(
                    'Jouer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: modeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreSection() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'EXPLOREZ ET GAGNEZ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        // Première rangée
        Row(
          children: [
            Expanded(
              child: _buildExploreCard(
                title: 'Mon Classement',
                icon: Icons.emoji_events,
                color: _DesignColors.primary,
                subtitle: 'N°${_userRank ?? 420} sur ${_totalPlayers ?? 10000}',
                onTap: _navigateToClassement,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildExploreCard(
                title: 'Challenge',
                icon: Icons.card_giftcard,
                color: _DesignColors.secondary,
                onTap: _navigateToChallenge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        // Deuxième rangée
        Row(
          children: [
            Expanded(
              child: _buildExploreCard(
                title: 'Défis Partenaires',
                icon: Icons.card_travel,
                color: _DesignColors.cyan,
                subtitle: 'Gagnez des trophées',
                onTap: _navigateToSponsoredChallenges,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Container(), // Placeholder optionnel
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExploreCard({
    required String title,
    required IconData icon,
    required Color color,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(colors.shadowOpacity),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Info button en haut à droite
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 4),
            // Icône avec fond coloré (style profile_screen)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget personnalisé du bouton buzzer style "Questions pour un Champion"
/// Effet 3D avec animation de pression satisfaisante
class _QuizBuzzerButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _QuizBuzzerButton({required this.onPressed});

  @override
  State<_QuizBuzzerButton> createState() => _QuizBuzzerButtonState();
}

class _QuizBuzzerButtonState extends State<_QuizBuzzerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _shadowAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                // Ombre extérieure principale
                BoxShadow(
                  color: const Color(0xFF6B4EAA).withOpacity(0.4 * _shadowAnimation.value),
                  blurRadius: 25 * _shadowAnimation.value,
                  spreadRadius: 5 * _shadowAnimation.value,
                  offset: Offset(0, 12 * _shadowAnimation.value),
                ),
                // Lueur violet
                BoxShadow(
                  color: const Color(0xFF9B7ED9).withOpacity(0.3 * _shadowAnimation.value),
                  blurRadius: 40 * _shadowAnimation.value,
                  spreadRadius: 10 * _shadowAnimation.value,
                ),
              ],
            ),
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Base du buzzer (anneau extérieur métallique)
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFE0E0E0),
                          const Color(0xFF9E9E9E),
                          const Color(0xFF757575),
                          const Color(0xFFBDBDBD),
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // Cercle intermédiaire (bord du bouton)
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF8B5CF6),
                          const Color(0xFF6B4EAA),
                          const Color(0xFF5B3E9A),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),

                  // Surface principale du buzzer
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 160,
                    height: 160,
                    transform: Matrix4.translationValues(
                      0,
                      _isPressed ? 4 : 0,
                      0,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.3),
                        radius: 0.8,
                        colors: _isPressed
                            ? [
                          const Color(0xFF7C3AED),
                          const Color(0xFF6B4EAA),
                          const Color(0xFF5B3E9A),
                        ]
                            : [
                          const Color(0xFFA78BFA),
                          const Color(0xFF8B5CF6),
                          const Color(0xFF7C3AED),
                        ],
                      ),
                      boxShadow: _isPressed
                          ? []
                          : [
                        // Effet 3D - ombre interne haute
                        BoxShadow(
                          color: Colors.white.withOpacity(0.4),
                          blurRadius: 0,
                          spreadRadius: 0,
                          offset: const Offset(-2, -2),
                        ),
                        // Effet 3D - ombre basse
                        BoxShadow(
                          color: const Color(0xFF4C1D95).withOpacity(0.8),
                          blurRadius: 0,
                          spreadRadius: 0,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  // Reflet brillant en haut
                  Positioned(
                    top: 25,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 100),
                      opacity: _isPressed ? 0.1 : 0.6,
                      child: Container(
                        width: 80,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.8),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Contenu textuel
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    transform: Matrix4.translationValues(
                      0,
                      _isPressed ? 4 : 0,
                      0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icône
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 40,
                          color: Colors.white.withOpacity(0.95),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'JOUER UN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'QUIZZ',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF4C1D95),
                                blurRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}