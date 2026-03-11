import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'sponsored_challenge_list_screen.dart';

/// Couleurs du design
class _DesignColors {
  static const Color primary = Color(0xFFFFB74D);
  static const Color secondary = Color(0xFF9C27B0);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color green = Color(0xFF4CAF50);
  static const Color pink = Color(0xFFE91E63);
}

/// Écran de résultat du challenge sponsorisé
class SponsoredChallengeResultScreen extends StatelessWidget {
  final SponsoredChallenge challenge;
  final int score;
  final int totalQuestions;
  final Map<String, dynamic>? result;

  const SponsoredChallengeResultScreen({
    super.key,
    required this.challenge,
    required this.score,
    required this.totalQuestions,
    this.result,
  });

  bool get isWon => (score / totalQuestions) >= 0.7;

  double get percentage => (score / totalQuestions) * 100;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final userState = context.watch<UserStateProvider>();
    final trophee = result?['tropheeGranted'];

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SponsoredChallengeListScreen(
              token: userState.token,
            ),
          ),
        );
        return false;
      },
      child: Scaffold(
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
                  // Header minimal
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SponsoredChallengeListScreen(
                                  token: userState.token,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(Icons.arrow_back,
                                color: colors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // Résultat principal
                          _buildResultCard(colors, userState),
                          const SizedBox(height: 32),
                          // Score détaillé
                          _buildScoreDetails(colors),
                          const SizedBox(height: 32),
                          // Trophée si gagné
                          if (isWon && trophee != null) ...[
                            _buildTrophyCard(colors),
                            const SizedBox(height: 32),
                          ],
                          // Stat card
                          _buildStatCard(colors),
                          const SizedBox(height: 40),
                          // Boutons
                          _buildActionButtons(context, userState),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      ),
    );
  }

  Widget _buildResultCard(ThemeColors colors, UserStateProvider userState) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Grande icône résultat
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isWon
                  ? _DesignColors.green.withOpacity(0.15)
                  : _DesignColors.pink.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWon ? Icons.check_circle : Icons.cancel,
              size: 56,
              color: isWon ? _DesignColors.green : _DesignColors.pink,
            ),
          ),
          const SizedBox(height: 24),
          // Message
          Text(
            isWon ? 'Bravo! Vous avez réussi!' : 'Défi non réussi',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isWon ? _DesignColors.green : _DesignColors.pink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isWon
                ? 'Vous avez gagné le trophée de ce défi!'
                : 'Vous devez obtenir au moins 70% pour réussir',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colors.textMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          // Pourcentage
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: _DesignColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDetails(ThemeColors colors) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _DesignColors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      color: _DesignColors.green, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bonnes réponses',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _DesignColors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _DesignColors.pink.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: _DesignColors.pink, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  'Mauvaises réponses',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalQuestions - score}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _DesignColors.pink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrophyCard(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _DesignColors.primary.withOpacity(0.2),
            _DesignColors.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _DesignColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _DesignColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events,
                size: 40, color: _DesignColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            '🏆 Trophée Déverrouillé!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous avez gagné le trophée exclusif\nde ce défi partenaire',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Défi',
            style: TextStyle(
              fontSize: 12,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            challenge.titre,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: colors.divider),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Récompense',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textMuted,
                ),
              ),
              Text(
                challenge.recompense,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _DesignColors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, UserStateProvider userState) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SponsoredChallengeListScreen(
                    token: userState.token,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.home),
            label: const Text('Retour aux défis'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
        ),
        if (!isWon) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _DesignColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: const BorderSide(
                  color: _DesignColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
