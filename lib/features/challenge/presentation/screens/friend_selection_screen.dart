import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../quiz/presentation/screens/game_screen.dart';
import '../../../social/presentation/screens/friends_screen.dart';


/// Modèle pour un ami
class Friend {
  final int id;
  final String nom;
  final String niveau;
  final int xp;
  final String? avatarUrl;

  Friend({
    required this.id,
    required this.nom,
    required this.niveau,
    required this.xp,
    this.avatarUrl,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    // Construire le niveau affiché
    final niveauStage = json['niveauStage'] ?? json['niveau'] ?? 1;
    final niveauStr = niveauStage is String ? niveauStage : 'Stage $niveauStage';
    
    return Friend(
      id: json['idJoueur'] ?? json['id'] ?? 0,
      nom: json['pseudo'] ?? json['nom'] ?? 'Ami',
      niveau: niveauStr,
      xp: json['totalXP'] ?? json['xpTotal'] ?? json['xp'] ?? 0,
      avatarUrl: json['avatarURL'] ?? json['avatar'],
    );
  }
}

/// Écran de sélection d'ami pour le mode "Défier un ami"
class FriendSelectionScreen extends StatefulWidget {
  final String? token;

  const FriendSelectionScreen({
    super.key,
    this.token,
  });

  @override
  State<FriendSelectionScreen> createState() => _FriendSelectionScreenState();
}

class _FriendSelectionScreenState extends State<FriendSelectionScreen> {
  List<Friend> _friends = [];
  bool _isLoading = true;
  int? _selectedFriendId;
  int _questionCount = 10;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer le token depuis le provider si non fourni
      final userState = context.read<UserStateProvider>();
      final token = widget.token ?? userState.token;
      
      if (token == null) {
        debugPrint('⚠️ Pas de token disponible');
        setState(() {
          _friends = _generateMockFriends();
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.friendsToChallenge)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📡 Réponse amis: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('📦 Data amis: ${data['data']?.length ?? 0} amis');
        
        if (data['success'] == true && data['data'] != null) {
          final friendsList = data['data'] as List;
          setState(() {
            _friends = friendsList.map((f) => Friend.fromJson(f)).toList();
            _isLoading = false;
          });
          return;
        }
      } else {
        debugPrint('❌ Erreur API: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement amis: $e');
    }

    // Fallback: générer des amis fictifs
    setState(() {
      _friends = _generateMockFriends();
      _isLoading = false;
    });
  }

  List<Friend> _generateMockFriends() {
    return [
      Friend(id: 1, nom: 'Tunde Gabriel', niveau: 'Stage 5-Emeraude', xp: 120),
      Friend(id: 2, nom: 'Tunde Gabriel', niveau: 'Stage 5-Emeraude', xp: 120),
      Friend(id: 3, nom: 'Tunde Gabriel', niveau: 'Stage 5-Emeraude', xp: 120),
      Friend(id: 4, nom: 'Tunde Gabriel', niveau: 'Stage 5-Emeraude', xp: 120),
    ];
  }

  void _inviteFriend() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FriendsScreen()),
    );
  }

  void _onValidate() async {
    if (_selectedFriendId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un ami'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedFriend = _friends.firstWhere((f) => f.id == _selectedFriendId);
    final userState = context.read<UserStateProvider>();

    // Afficher le dialogue de mise
    final betAmount = await _showBetDialog(userState.coins);
    
    if (betAmount == null || !mounted) return;

    // Naviguer vers le jeu avec l'ami sélectionné
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          userName: userState.userName,
          userLevel: userState.userLevel,
          userLives: userState.lives,
          userCoins: userState.coins,
          avatarUrl: userState.avatarUrl,
          token: widget.token,
          mode: 'friend_challenge',
          nombreQuestions: _questionCount,
          opponentName: selectedFriend.nom,
          opponentId: selectedFriend.id,
          coinsBet: betAmount,
        ),
      ),
    );
  }

  Future<int?> _showBetDialog(int userCoins) async {
    final List<int> betOptions = [10, 25, 50, 100];
    int? selectedBet;

    return showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB74D).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.monetization_on, color: Color(0xFFFFB74D), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Miser des coins',
                    style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Vos coins:', style: TextStyle(color: Colors.black54)),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on, color: Color(0xFFFFB74D), size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '$userCoins',
                              style: const TextStyle(
                                color: Color(0xFFFFB74D),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Choisissez votre mise:',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: betOptions.map((bet) {
                      final isAvailable = userCoins >= bet;
                      final isSelected = selectedBet == bet;
                      return GestureDetector(
                        onTap: isAvailable ? () => setState(() => selectedBet = bet) : null,
                        child: Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFFB74D)
                                : isAvailable
                                    ? Colors.grey[100]
                                    : Colors.grey[100]!.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFFB74D)
                                  : isAvailable
                                      ? Colors.grey[300]!
                                      : Colors.grey[200]!.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.monetization_on,
                                color: isSelected
                                    ? Colors.white
                                    : isAvailable
                                        ? const Color(0xFFFFB74D)
                                        : Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$bet',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : isAvailable
                                          ? Colors.black87
                                          : Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (userCoins < 10) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFE91E63), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vous n\'avez pas assez de coins pour défier.',
                              style: TextStyle(color: Color(0xFFE91E63), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF00BCD4), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Si vous gagnez, vous récupérez le double de votre mise!',
                            style: TextStyle(color: Color(0xFF00BCD4), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler', style: TextStyle(color: Colors.black54)),
                ),
                ElevatedButton(
                  onPressed: selectedBet != null ? () => Navigator.pop(context, selectedBet) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EAA),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF6B4EAA).withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Défier !'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _returnToMainMenu() {
    Navigator.pop(context);
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
                  title: 'Selectionnez un ami',
                  onBackTap: () => Navigator.of(context).pop(), centerTitle: true,
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6B4EAA),
                    ),
                  )
                      : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // Sous-titre
                        const Text(
                          'ou',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Bouton Inviter un ami
                        _buildInviteButton(),

                        const SizedBox(height: 30),

                        // Liste des amis
                        ..._friends.map((friend) => _buildFriendCard(friend)),

                        const SizedBox(height: 30),

                        // Bouton Valider
                        _buildValidateButton(),

                        const SizedBox(height: 16),

                        // Lien Retour au menu principal
                        TextButton(
                          onPressed: _returnToMainMenu,
                          child: const Text(
                            'Retour au menu principal',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
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

  Widget _buildInviteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _inviteFriend,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFB74D),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Inviter un ami',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFriendCard(Friend friend) {
    final isSelected = _selectedFriendId == friend.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFriendId = friend.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B4EAA) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[200],
              backgroundImage:
              friend.avatarUrl != null ? NetworkImage(friend.avatarUrl!) : null,
              child: friend.avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.grey, size: 30)
                  : null,
            ),
            const SizedBox(width: 12),

            // Nom et niveau
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.nom,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    friend.niveau,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // XP
            Text(
              '${friend.xp}XP',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedFriendId != null ? _onValidate : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8D44D),
          foregroundColor: Colors.black87,
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
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
    );
  }
}