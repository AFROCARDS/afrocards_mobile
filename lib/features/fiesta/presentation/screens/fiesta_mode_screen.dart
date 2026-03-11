import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../challenge/presentation/screens/challenge_question_count_screen.dart';
import '../../../challenge/presentation/screens/friend_selection_screen.dart';
import '../../../quiz/presentation/screens/game_screen.dart';

/// Couleurs du design (identiques à profile_screen)
class _DesignColors {
  static const Color primary = Color(0xFFFFB74D);
  static const Color secondary = Color(0xFF9C27B0);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color pink = Color(0xFFE91E63);
  static const Color orange = Color(0xFFFF9800);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);
}

/// Modèle pour un sous-mode Fiesta
class FiestaSubMode {
  final int idSousMode;
  final String nom;
  final String? description;
  final String? icone;
  final int ordre;
  final Map<String, dynamic>? configuation;

  FiestaSubMode({
    required this.idSousMode,
    required this.nom,
    this.description,
    this.icone,
    this.ordre = 1,
    this.configuation,
  });

  factory FiestaSubMode.fromJson(Map<String, dynamic> json) {
    return FiestaSubMode(
      idSousMode: json['idSousMode'] ?? json['id_sous_mode'],
      nom: json['nom'],
      description: json['description'],
      icone: json['icone'],
      ordre: json['ordre'] ?? 1,
      configuation: json['configuation'],
    );
  }
}

/// Écran du mode Fiesta avec sélection des sous-modes
class FiestaModeScreen extends StatefulWidget {
  final String? userName;
  final String? userLevel;
  final int? userPoints;
  final int? userLives;
  final String? avatarUrl;
  final String? token;

  const FiestaModeScreen({
    super.key,
    this.userName,
    this.userLevel,
    this.userPoints,
    this.userLives,
    this.avatarUrl,
    this.token,
  });

  @override
  State<FiestaModeScreen> createState() => _FiestaModeScreenState();
}

class _FiestaModeScreenState extends State<FiestaModeScreen> {
  List<FiestaSubMode> _subModes = [];
  bool _isLoading = true;
  String? _error;
  FiestaSubMode? _selectedSubMode;

  @override
  void initState() {
    super.initState();
    _loadSubModes();
  }

  Future<void> _loadSubModes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.fiestaSousModes)),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final subModesList = data['data'] as List? ?? [];
        setState(() {
          _subModes = subModesList.map((s) => FiestaSubMode.fromJson(s)).toList();
          _isLoading = false;
        });
        debugPrint('Sous-modes Fiesta chargés: ${_subModes.length}');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur chargement sous-modes: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _subModes = _generateTestSubModes();
      });
    }
  }

  List<FiestaSubMode> _generateTestSubModes() {
    return [
      FiestaSubMode(
        idSousMode: 1,
        nom: 'Challenge',
        description: 'Relevez des défis quotidiens et hebdomadaires pour gagner des récompenses spéciales !',
        icone: 'trophy',
        ordre: 1,
      ),
      FiestaSubMode(
        idSousMode: 2,
        nom: 'Aleatoire',
        description: 'Questions aléatoires de toutes catégories. Testez vos connaissances générales !',
        icone: 'shuffle',
        ordre: 2,
      ),
      FiestaSubMode(
        idSousMode: 3,
        nom: 'Defier des amis',
        description: 'Défiez vos amis en duel et prouvez que vous êtes le meilleur !',
        icone: 'people',
        ordre: 3,
      ),
    ];
  }

  void _onSubModeSelected(FiestaSubMode subMode) {
    setState(() {
      _selectedSubMode = subMode;
    });
  }

  void _showSubModeInfo(FiestaSubMode subMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: context.colors.cardBackground,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _DesignColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.info_outline, color: _DesignColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                subMode.nom,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.colors.textPrimary),
              ),
            ),
          ],
        ),
        content: Text(
          subMode.description ?? 'Aucune description disponible',
          style: const TextStyle(color: _DesignColors.textMuted, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _DesignColors.textMuted,
            ),
            child: const Text('Fermer', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _onSuivantPressed() {
    if (_selectedSubMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Veuillez sélectionner un mode de jeu'),
            ],
          ),
          backgroundColor: _DesignColors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    debugPrint('Sous-mode sélectionné: ${_selectedSubMode!.nom}');

    final subModeName = _selectedSubMode!.nom.toLowerCase();

    if (subModeName.contains('challenge')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChallengeQuestionCountScreen(
            token: widget.token,
          ),
        ),
      );
    } else if (subModeName.contains('aleatoire') || subModeName.contains('aléatoire')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            userName: widget.userName,
            userLevel: widget.userLevel,
            userLives: widget.userLives,
            userCoins: widget.userPoints,
            avatarUrl: widget.avatarUrl,
            token: widget.token,
            nombreQuestions: 10,
            mode: 'random',
          ),
        ),
      );
    } else if (subModeName.contains('defier') || subModeName.contains('amis')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FriendSelectionScreen(
            token: widget.token,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            userName: widget.userName,
            userLevel: widget.userLevel,
            userLives: widget.userLives,
            userCoins: widget.userPoints,
            avatarUrl: widget.avatarUrl,
            token: widget.token,
            nombreQuestions: 10,
            mode: 'random',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      body: Stack(
        children: [
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
                  onBackTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: _DesignColors.primary))
                      : _error != null && _subModes.isEmpty
                          ? _buildErrorState()
                          : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _DesignColors.pink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 48, color: _DesignColors.pink),
            ),
            const SizedBox(height: 20),
            Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Impossible de charger les modes de jeu',
              style: TextStyle(color: _DesignColors.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSubModes,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _DesignColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildHeaderCard(),
                const SizedBox(height: 24),
                _buildSubModesSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _buildSuivantButton(),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _DesignColors.primary.withOpacity(0.2),
                  _DesignColors.orange.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.celebration_rounded, size: 40, color: _DesignColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Mode Fiesta',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sélectionnez le mode de jeu\nqui vous convient',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _DesignColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubModesSection() {
    if (_subModes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Aucun mode disponible',
            style: TextStyle(color: _DesignColors.textMuted),
          ),
        ),
      );
    }

    return Column(
      children: _subModes.map((subMode) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildSubModeCard(subMode),
      )).toList(),
    );
  }

  Widget _buildSubModeCard(FiestaSubMode subMode) {
    final isSelected = _selectedSubMode?.idSousMode == subMode.idSousMode;
    final subModeName = subMode.nom.toLowerCase();

    IconData modeIcon;
    Color accentColor;

    if (subModeName.contains('challenge')) {
      modeIcon = Icons.emoji_events_rounded;
      accentColor = _DesignColors.orange;
    } else if (subModeName.contains('aleatoire') || subModeName.contains('aléatoire')) {
      modeIcon = Icons.casino_rounded;
      accentColor = _DesignColors.cyan;
    } else if (subModeName.contains('defier') || subModeName.contains('amis')) {
      modeIcon = Icons.people_alt_rounded;
      accentColor = _DesignColors.pink;
    } else {
      modeIcon = Icons.star_rounded;
      accentColor = _DesignColors.secondary;
    }

    return GestureDetector(
      onTap: () => _onSubModeSelected(subMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: accentColor, width: 2.5)
              : Border.all(color: Colors.grey.shade100, width: 1),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accentColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icône
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(isSelected ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                modeIcon,
                size: 28,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 16),
            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subMode.nom,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? accentColor : _DesignColors.textDark,
                    ),
                  ),
                  if (subMode.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subMode.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _DesignColors.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Indicateur de sélection
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuivantButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onSuivantPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Suivant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
