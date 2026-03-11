import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

/// Modèle pour un joueur dans le classement
class ClassementPlayer {
  final int rank;
  final int? idJoueur;
  final String nom;
  final String? avatar;
  final int xp;
  final String niveau;
  final String? badge;
  final bool isCurrentUser;

  ClassementPlayer({
    required this.rank,
    this.idJoueur,
    required this.nom,
    this.avatar,
    required this.xp,
    required this.niveau,
    this.badge,
    this.isCurrentUser = false,
  });

  factory ClassementPlayer.fromJson(Map<String, dynamic> json,
      {bool isCurrentUser = false}) {
    return ClassementPlayer(
      rank: json['rang'] ?? json['rank'] ?? json['position'] ?? 0,
      idJoueur: json['idJoueur'],
      nom: json['pseudo'] ?? json['nom'] ?? 'Joueur',
      avatar: json['avatarURL'] ?? json['avatar'] ?? json['avatarUrl'],
      xp: json['xpTotal'] ?? json['xp'] ?? json['points'] ?? json['score'] ?? 0,
      niveau: json['niveau'] ?? json['stage'] ?? 'Stage 1',
      badge: json['badge'] ?? json['titre'],
      isCurrentUser: json['isCurrentUser'] == true || isCurrentUser,
    );
  }
}

/// Écran de classement avec 3 onglets: Monde, Mensuel, Ami(e)s
class ClassementScreen extends StatefulWidget {
  final String? userName;
  final String? userLevel;
  final int? userLives;
  final int? userCoins;
  final String? avatarUrl;
  final String? token;

  const ClassementScreen({
    super.key,
    this.userName,
    this.userLevel,
    this.userLives,
    this.userCoins,
    this.avatarUrl,
    this.token,
  });

  @override
  State<ClassementScreen> createState() => _ClassementScreenState();
}

class _ClassementScreenState extends State<ClassementScreen> {
  int _selectedTabIndex = 0;

  List<ClassementPlayer> _mondePlayers = [];
  List<ClassementPlayer> _mensuelPlayers = [];
  List<ClassementPlayer> _amisPlayers = [];

  ClassementPlayer? _currentUserMonde;
  ClassementPlayer? _currentUserMensuel;

  bool _isLoading = true;
  String? _error;

  final List<String> _tabs = ['Monde', 'Mensuel', 'Ami(e)s'];

  @override
  void initState() {
    super.initState();
    _loadClassement();
  }

  Future<void> _loadClassement() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Charger tous les classements en parallèle
      await Future.wait([
        _fetchClassement(ApiEndpoints.classementGlobal, 0),
        _fetchClassement(ApiEndpoints.classementMensuel, 1),
        _fetchClassement(ApiEndpoints.classementAmis, 2),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement classement: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Données de test différentes pour chaque onglet
        _mondePlayers = _generateTestPlayers(tabIndex: 0);
        _mensuelPlayers = _generateTestPlayers(tabIndex: 1);
        _amisPlayers = _generateTestPlayers(tabIndex: 2);
      });
    }
  }

  Future<void> _fetchClassement(String endpoint, int tabIndex) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(endpoint)),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final playersList = data['data'] as List? ?? [];
        final players =
            playersList.map((p) => ClassementPlayer.fromJson(p)).toList();

        // Récupérer l'utilisateur courant s'il n'est pas dans la liste
        ClassementPlayer? currentUser;
        if (data['currentUser'] != null) {
          currentUser =
              ClassementPlayer.fromJson(data['currentUser'], isCurrentUser: true);
        }

        setState(() {
          switch (tabIndex) {
            case 0:
              _mondePlayers = players;
              _currentUserMonde = currentUser;
              break;
            case 1:
              _mensuelPlayers = players;
              _currentUserMensuel = currentUser;
              break;
            case 2:
              _amisPlayers = players;
              break;
          }
        });
      }
    } catch (e) {
      debugPrint('Erreur fetch $endpoint: $e');
      // Utiliser les données de test en cas d'erreur
      final testPlayers = _generateTestPlayers(tabIndex: tabIndex);
      setState(() {
        switch (tabIndex) {
          case 0:
            _mondePlayers = testPlayers;
            break;
          case 1:
            _mensuelPlayers = testPlayers;
            break;
          case 2:
            _amisPlayers = testPlayers;
            break;
        }
      });
    }
  }

  List<ClassementPlayer> _generateTestPlayers({int tabIndex = 0}) {
    final userState = context.read<UserStateProvider>();
    
    // Données de test différentes selon l'onglet
    List<Map<String, dynamic>> testData;
    
    switch (tabIndex) {
      case 0: // Monde - Classement global par XP total
        testData = [
          {'nom': 'Kwame Asante', 'niveau': 'Stage 25', 'badge': 'Diamant', 'xp': 5000},
          {'nom': 'Amara Diallo', 'niveau': 'Stage 22', 'badge': 'Platine', 'xp': 4200},
          {'nom': 'Zuri Okonkwo', 'niveau': 'Stage 20', 'badge': 'Or', 'xp': 3800},
          {'nom': 'Kofi Mensah', 'niveau': 'Stage 18', 'badge': 'Or', 'xp': 3200},
          {'nom': 'Fatou Ndiaye', 'niveau': 'Stage 15', 'badge': 'Argent', 'xp': 2500},
          {'nom': userState.userName, 'niveau': 'Stage ${userState.currentStageLevel}', 'badge': 'Emeraude', 'xp': userState.pointsXP, 'avatar': userState.avatarUrl, 'isCurrentUser': true},
          {'nom': 'Yemi Adeyemi', 'niveau': 'Stage 12', 'badge': 'Emeraude', 'xp': 1800},
          {'nom': 'Oumar Bah', 'niveau': 'Stage 10', 'badge': 'Bronze', 'xp': 1200},
        ];
        break;
        
      case 1: // Mensuel - Classement du mois en cours
        testData = [
          {'nom': 'Amara Diallo', 'niveau': 'Stage 22', 'badge': 'Platine', 'xp': 850},
          {'nom': 'Zuri Okonkwo', 'niveau': 'Stage 20', 'badge': 'Or', 'xp': 720},
          {'nom': userState.userName, 'niveau': 'Stage ${userState.currentStageLevel}', 'badge': 'Emeraude', 'xp': userState.pointsXP > 0 ? (userState.pointsXP ~/ 3) : 0, 'avatar': userState.avatarUrl, 'isCurrentUser': true},
          {'nom': 'Kwame Asante', 'niveau': 'Stage 25', 'badge': 'Diamant', 'xp': 580},
          {'nom': 'Kofi Mensah', 'niveau': 'Stage 18', 'badge': 'Or', 'xp': 450},
          {'nom': 'Fatou Ndiaye', 'niveau': 'Stage 15', 'badge': 'Argent', 'xp': 320},
        ];
        break;
        
      case 2: // Ami(e)s - Classement des amis
        testData = [
          {'nom': 'Thibaut Hounton', 'niveau': 'Stage 15', 'badge': 'Argent', 'xp': 2500},
          {'nom': userState.userName, 'niveau': 'Stage ${userState.currentStageLevel}', 'badge': 'Emeraude', 'xp': userState.pointsXP, 'avatar': userState.avatarUrl, 'isCurrentUser': true},
          {'nom': 'Adama Traoré', 'niveau': 'Stage 8', 'badge': 'Bronze', 'xp': 800},
          {'nom': 'Mariama Sow', 'niveau': 'Stage 5', 'badge': 'Bronze', 'xp': 450},
        ];
        break;
        
      default:
        testData = [];
    }
    
    // Trier par XP décroissant
    testData.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));

    return testData.asMap().entries.map((entry) {
      return ClassementPlayer(
        rank: entry.key + 1,
        nom: entry.value['nom'] as String,
        niveau: entry.value['niveau'] as String,
        badge: entry.value['badge'] as String?,
        xp: entry.value['xp'] as int,
        avatar: entry.value['avatar'] as String?,
        isCurrentUser: entry.value['isCurrentUser'] == true,
      );
    }).toList();
  }

  List<ClassementPlayer> get _currentPlayers {
    switch (_selectedTabIndex) {
      case 0:
        return _mondePlayers;
      case 1:
        return _mensuelPlayers;
      case 2:
        return _amisPlayers;
      default:
        return _mondePlayers;
    }
  }

  ClassementPlayer? get _currentUserNotInList {
    switch (_selectedTabIndex) {
      case 0:
        return _currentUserMonde;
      case 1:
        return _currentUserMensuel;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(colors.backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              AppHeader(
                onAvatarTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                }, centerTitle: true,
              ),

              // Titre avec flèche retour
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                    const Expanded(
                      child: Text(
                        'Classement',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tabs
              _buildTabs(),

              const SizedBox(height: 20),

              // Liste des joueurs
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF6B4EAA)),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadClassement,
                        color: const Color(0xFF6B4EAA),
                        child: _buildPlayersList(),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(
        currentIndex: 0,
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = _selectedTabIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFFF5F0FF) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: const Color(0xFF6B4EAA), width: 1.5)
                    : Border.all(color: Colors.transparent),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF6B4EAA) : Colors.black54,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlayersList() {
    final players = _currentPlayers;
    final currentUserNotInList = _currentUserNotInList;

    if (players.isEmpty && currentUserNotInList == null) {
      return const Center(
        child: Text(
          'Aucun joueur dans le classement',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Nombre total d'éléments (joueurs + éventuellement l'utilisateur + séparateur)
    final hasCurrentUserSeparate = currentUserNotInList != null;
    final itemCount =
        players.length + (hasCurrentUserSeparate ? 2 : 0); // +2 pour séparateur + user

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: itemCount,
      separatorBuilder: (context, index) {
        // Si c'est le séparateur avant l'utilisateur courant
        if (hasCurrentUserSeparate && index == players.length) {
          return const SizedBox(height: 8);
        }
        return Divider(
          color: Colors.grey.shade200,
          height: 1,
        );
      },
      itemBuilder: (context, index) {
        // Si c'est le séparateur "Votre position"
        if (hasCurrentUserSeparate && index == players.length) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Votre position',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B4EAA),
                ),
              ),
            ),
          );
        }

        // Si c'est l'utilisateur courant (affiché à la fin)
        if (hasCurrentUserSeparate && index == players.length + 1) {
          return _buildPlayerTile(currentUserNotInList);
        }

        final player = players[index];
        return _buildPlayerTile(player);
      },
    );
  }

  Widget _buildPlayerTile(ClassementPlayer player) {
    final userState = context.watch<UserStateProvider>();
    
    // Si c'est l'utilisateur courant, utiliser les données synchronisées du provider
    final bool isCurrentUser = player.isCurrentUser;
    final String levelDisplay;
    final int displayXp;
    
    if (isCurrentUser) {
      // Utiliser les données du provider pour l'utilisateur courant
      levelDisplay = 'Stage ${userState.currentStageLevel}';
      displayXp = userState.pointsXP;
    } else {
      // Pour les autres joueurs, utiliser les données du classement
      levelDisplay = player.niveau;
      displayXp = player.xp;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isCurrentUser
          ? BoxDecoration(
              color: const Color(0xFFF5F0FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6B4EAA), width: 1.5),
            )
          : null,
      child: Padding(
        padding: isCurrentUser
            ? const EdgeInsets.symmetric(horizontal: 12)
            : EdgeInsets.zero,
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  player.avatar != null && player.avatar!.isNotEmpty
                      ? NetworkImage(player.avatar!)
                      : null,
              child: player.avatar == null || player.avatar!.isEmpty
                  ? Icon(Icons.person, color: Colors.grey[400], size: 28)
                  : null,
            ),
            const SizedBox(width: 14),

            // Nom et niveau
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCurrentUser ? userState.userName : player.nom,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isCurrentUser
                          ? const Color(0xFF6B4EAA)
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    levelDisplay,
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
              '${displayXp}XP',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isCurrentUser
                    ? const Color(0xFF6B4EAA)
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
