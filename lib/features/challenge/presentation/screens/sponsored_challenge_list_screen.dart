import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'sponsored_challenge_detail_screen.dart';

/// Modèle pour un challenge sponsorisé
class SponsoredChallenge {
  final int idChallenge;
  final int idPartenaire;
  final String titre;
  final String? description;
  final String recompense;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String statut;
  final Map<String, dynamic>? partenaire;

  SponsoredChallenge({
    required this.idChallenge,
    required this.idPartenaire,
    required this.titre,
    this.description,
    required this.recompense,
    required this.dateDebut,
    required this.dateFin,
    required this.statut,
    this.partenaire,
  });

  factory SponsoredChallenge.fromJson(Map<String, dynamic> json) {
    return SponsoredChallenge(
      idChallenge: json['idChallenge'] ?? 0,
      idPartenaire: json['idPartenaire'] ?? 0,
      titre: json['titre'] ?? '',
      description: json['description'],
      recompense: json['recompense'] ?? '',
      dateDebut: DateTime.parse(json['dateDebut'] ?? DateTime.now().toIso8601String()),
      dateFin: DateTime.parse(json['dateFin'] ?? DateTime.now().toIso8601String()),
      statut: json['statut'] ?? 'actif',
      partenaire: json['Partenaire'],
    );
  }

  bool get isExpired => DateTime.now().isAfter(dateFin);
}

/// Couleurs du design
class _DesignColors {
  static const Color primary = Color(0xFFFFB74D);
  static const Color secondary = Color(0xFF9C27B0);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color green = Color(0xFF4CAF50);
  static const Color pink = Color(0xFFE91E63);
}

/// Écran listant tous les challenges sponsorisés
class SponsoredChallengeListScreen extends StatefulWidget {
  final String? token;

  const SponsoredChallengeListScreen({
    super.key,
    this.token,
  });

  @override
  State<SponsoredChallengeListScreen> createState() =>
      _SponsoredChallengeListScreenState();
}

class _SponsoredChallengeListScreenState
    extends State<SponsoredChallengeListScreen> {
  List<SponsoredChallenge> _challenges = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userState = context.read<UserStateProvider>();
      final token = widget.token ?? userState.token;

      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl('/api/challenges-sponsorises/active')),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final challengesList = (data['data'] as List? ?? [])
            .map((c) => SponsoredChallenge.fromJson(c))
            .toList();

        setState(() {
          _challenges = challengesList;
          _isLoading = false;
        });
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur chargement challenges: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToDetail(SponsoredChallenge challenge) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SponsoredChallengeDetailScreen(
          challenge: challenge,
          token: widget.token,
        ),
      ),
    );
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
                // Header
                AppHeader(
                  onAvatarTap: () => Navigator.pop(context),
                  centerTitle: true,
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                          child: Icon(Icons.arrow_back, color: colors.textPrimary),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Défis Partenaires',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _DesignColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.card_giftcard,
                            color: _DesignColors.primary),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: _DesignColors.primary),
                        )
                      : _error != null
                          ? _buildErrorState()
                          : _challenges.isEmpty
                              ? _buildEmptyState()
                              : _buildChallengesList(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildErrorState() {
    final colors = context.colors;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
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
              child: const Icon(Icons.error_outline,
                  size: 48, color: _DesignColors.pink),
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadChallenges,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _DesignColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = context.colors;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _DesignColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard,
                  size: 48, color: _DesignColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun défi disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Revenez plus tard pour de nouveaux défis',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengesList() {
    final colors = context.colors;
    return RefreshIndicator(
      onRefresh: _loadChallenges,
      color: _DesignColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _challenges.length,
        itemBuilder: (context, index) {
          final challenge = _challenges[index];
          return _buildChallengeCard(challenge, colors);
        },
      ),
    );
  }

  Widget _buildChallengeCard(SponsoredChallenge challenge, ThemeColors colors) {
    final partnerName = challenge.partenaire?['entreprise'] ?? 'Partenaire';
    final daysLeft =
        challenge.dateFin.difference(DateTime.now()).inDays;
    final isExpired = challenge.isExpired;

    return GestureDetector(
      onTap: isExpired ? null : () => _navigateToDetail(challenge),
      child: Opacity(
        opacity: isExpired ? 0.6 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header avec partenaire
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _DesignColors.primary.withOpacity(0.2),
                    _DesignColors.primary.withOpacity(0.1),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _DesignColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.card_giftcard,
                        color: _DesignColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partnerName,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          challenge.titre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isExpired)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _DesignColors.pink.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Expiré',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _DesignColors.pink,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  if (challenge.description != null) ...[
                    Text(
                      challenge.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textMuted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Récompense et timing
                  Row(
                    children: [
                      // Récompense
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _DesignColors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.emoji_events,
                                      size: 14,
                                      color: _DesignColors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Récompense',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                challenge.recompense,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _DesignColors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Temps restant
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _DesignColors.cyan.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.schedule,
                                      size: 14,
                                      color: _DesignColors.cyan),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expire dans',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$daysLeft jour${daysLeft > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: daysLeft <= 3
                                      ? _DesignColors.pink
                                      : _DesignColors.cyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Bouton
                  if (!isExpired)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToDetail(challenge),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Voir le défi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _DesignColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
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
}
