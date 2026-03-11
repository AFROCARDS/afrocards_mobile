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
import 'friend_challenge_category_screen.dart';


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

    // Naviguer vers la sélection de catégorie
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendChallengeCategoryScreen(
          token: widget.token,
          friendId: selectedFriend.id,
          friendName: selectedFriend.nom,
          coinsBet: betAmount,
          questionCount: _questionCount,
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
              backgroundColor: context.colors.cardBackground,
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
                  title: 'Sélectionnez un ami',
                  onBackTap: () => Navigator.of(context).pop(),
                  centerTitle: true,
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFFFFB74D)),
                        )
                      : _friends.isEmpty
                          ? _buildEmptyState()
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  // Info card
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: colors.cardBackground,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFFFB74D),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFB74D).withOpacity(0.1),
                                          blurRadius: 15,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFB74D).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.people,
                                            color: Color(0xFFFFB74D),
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Vos compatriotes',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFFFB74D),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${_friends.length} amis disponibles',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Friends list
                                  ..._friends.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final friend = entry.value;
                                    return _buildFriendCard(friend, index);
                                  }).toList(),
                                  const SizedBox(height: 20),
                                  // Invite button
                                  _buildInviteButton(),
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
      bottomNavigationBar: _selectedFriendId != null
          ? Container(
              color: colors.cardBackground,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _onValidate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB74D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Défier !',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 48,
                color: Color(0xFFFFB74D),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun ami disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Invitez des amis pour commencer à jouer !',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _inviteFriend,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB74D),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Inviter un ami'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _inviteFriend,
        icon: const Icon(Icons.person_add),
        label: const Text('Inviter un ami'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9C27B0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildFriendCard(Friend friend, int index) {
    final isSelected = _selectedFriendId == friend.id;
    final selectionColor = const [
      Color(0xFFFFB74D),
      Color(0xFF9C27B0),
      Color(0xFF00BCD4),
      Color(0xFF4CAF50),
      Color(0xFFE91E63),
      Color(0xFF607D8B),
    ][index % 6];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFriendId = isSelected ? null : friend.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? selectionColor.withOpacity(0.1) : context.colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? selectionColor : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? selectionColor.withOpacity(0.15) : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar avec bordure
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? selectionColor : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[200],
                backgroundImage: friend.avatarUrl != null
                    ? NetworkImage(friend.avatarUrl!)
                    : null,
                child: friend.avatarUrl == null
                    ? Icon(
                        Icons.person,
                        color: Colors.grey[400],
                        size: 32,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.nom,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? selectionColor : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: selectionColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          friend.niveau,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: selectionColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.bolt,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${friend.xp} XP',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Check icon
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selectionColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: selectionColor,
                  size: 22,
                ),
              )
            else
              const SizedBox(width: 38),
          ],
        ),
      ),
    );
  }
}