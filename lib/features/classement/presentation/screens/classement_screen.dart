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
import '../../../social/presentation/screens/player_profile_screen.dart';

/// Couleurs du design (identiques à profile_screen)
class _DesignColors {
  static const Color primary = Color(0xFFFFB74D);      // Orange principal
  static const Color secondary = Color(0xFF9C27B0);    // Violet
  static const Color cyan = Color(0xFF00BCD4);         // Cyan
  static const Color pink = Color(0xFFE91E63);         // Rose
  static const Color green = Color(0xFF4CAF50);        // Vert
  static const Color textDark = Color(0xFF2D3436);     // Texte foncé
  static const Color textMuted = Color(0xFF636E72);    // Texte atténué
  
  // Couleurs pour le podium
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);
}

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

class _ClassementScreenState extends State<ClassementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<ClassementPlayer> _mondePlayers = [];
  List<ClassementPlayer> _mensuelPlayers = [];
  List<ClassementPlayer> _amisPlayers = [];

  ClassementPlayer? _currentUserMonde;
  ClassementPlayer? _currentUserMensuel;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadClassement();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClassement() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
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
        _mondePlayers = _generateTestPlayers(tabIndex: 0);
        _mensuelPlayers = _generateTestPlayers(tabIndex: 1);
        _amisPlayers = _generateTestPlayers(tabIndex: 2);
      });
    }
  }

  Future<void> _fetchClassement(String endpoint, int tabIndex) async {
    try {
      final userState = context.read<UserStateProvider>();
      final token = widget.token ?? userState.token;
      
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(endpoint)),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final playersList = data['data'] as List? ?? [];
        final players = playersList.map((p) => ClassementPlayer.fromJson(p)).toList();

        ClassementPlayer? currentUser;
        if (data['currentUser'] != null) {
          currentUser = ClassementPlayer.fromJson(data['currentUser'], isCurrentUser: true);
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
    
    List<Map<String, dynamic>> testData;
    
    switch (tabIndex) {
      case 0:
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
        
      case 1:
        testData = [
          {'nom': 'Amara Diallo', 'niveau': 'Stage 22', 'badge': 'Platine', 'xp': 850},
          {'nom': 'Zuri Okonkwo', 'niveau': 'Stage 20', 'badge': 'Or', 'xp': 720},
          {'nom': userState.userName, 'niveau': 'Stage ${userState.currentStageLevel}', 'badge': 'Emeraude', 'xp': userState.pointsXP > 0 ? (userState.pointsXP ~/ 3) : 0, 'avatar': userState.avatarUrl, 'isCurrentUser': true},
          {'nom': 'Kwame Asante', 'niveau': 'Stage 25', 'badge': 'Diamant', 'xp': 580},
          {'nom': 'Kofi Mensah', 'niveau': 'Stage 18', 'badge': 'Or', 'xp': 450},
          {'nom': 'Fatou Ndiaye', 'niveau': 'Stage 15', 'badge': 'Argent', 'xp': 320},
        ];
        break;
        
      case 2:
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
    switch (_tabController.index) {
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
    switch (_tabController.index) {
      case 0:
        return _currentUserMonde;
      case 1:
        return _currentUserMensuel;
      default:
        return null;
    }
  }

  void _navigateToPlayerProfile(int? idJoueur) {
    if (idJoueur != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerProfileScreen(idJoueur: idJoueur),
        ),
      );
    }
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
                  onAvatarTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                  centerTitle: true,
                ),
                
                // Title Section
                _buildTitleSection(),
                
                const SizedBox(height: 16),
                
                // Tabs
                _buildTabBar(),
                
                const SizedBox(height: 16),
                
                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _DesignColors.primary),
                        )
                      : _error != null && _currentPlayers.isEmpty
                          ? _buildErrorState()
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildClassementContent(0),
                                _buildClassementContent(1),
                                _buildClassementContent(2),
                              ],
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildTitleSection() {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back, color: colors.textPrimary, size: 20),
            ),
          ),
          Expanded(
            child: Text(
              'Classement',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          // Icon placeholder for balance
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _DesignColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events, color: _DesignColors.primary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _DesignColors.primary,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.public, size: 16),
                SizedBox(width: 6),
                Text('Monde'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month, size: 16),
                SizedBox(width: 6),
                Text('Mensuel'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 16),
                SizedBox(width: 6),
                Text('Amis'),
              ],
            ),
          ),
        ],
      ),
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
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
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
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impossible de charger le classement',
              style: TextStyle(color: colors.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadClassement,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _DesignColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassementContent(int tabIndex) {
    final players = _getPlayersForTab(tabIndex);
    final currentUserNotInList = _getCurrentUserForTab(tabIndex);

    if (players.isEmpty && currentUserNotInList == null) {
      return _buildEmptyState(tabIndex);
    }

    return RefreshIndicator(
      onRefresh: _loadClassement,
      color: _DesignColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Podium pour le top 3
            if (players.length >= 3) _buildPodium(players.take(3).toList()),
            
            const SizedBox(height: 16),
            
            // Liste des joueurs (à partir du 4ème)
            _buildPlayersList(players.length > 3 ? players.skip(3).toList() : players, startRank: 4),
            
            // User position si pas dans le top
            if (currentUserNotInList != null) ...[
              const SizedBox(height: 12),
              _buildYourPositionCard(currentUserNotInList),
            ],
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<ClassementPlayer> _getPlayersForTab(int tabIndex) {
    switch (tabIndex) {
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

  ClassementPlayer? _getCurrentUserForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _currentUserMonde;
      case 1:
        return _currentUserMensuel;
      default:
        return null;
    }
  }

  Widget _buildEmptyState(int tabIndex) {
    final colors = context.colors;
    String title;
    String subtitle;
    IconData icon;
    
    switch (tabIndex) {
      case 0:
        title = 'Aucun joueur';
        subtitle = 'Le classement mondial est vide';
        icon = Icons.public_off;
        break;
      case 1:
        title = 'Pas encore de classement';
        subtitle = 'Jouez ce mois-ci pour apparaître';
        icon = Icons.calendar_today;
        break;
      case 2:
        title = 'Pas encore d\'amis';
        subtitle = 'Ajoutez des amis pour les défier';
        icon = Icons.group_add;
        break;
      default:
        title = 'Aucun joueur';
        subtitle = 'Le classement est vide';
        icon = Icons.leaderboard;
    }

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
                color: _DesignColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: _DesignColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium(List<ClassementPlayer> topThree) {
    final colors = context.colors;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _DesignColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events, color: _DesignColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Top 3',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2ème place
              if (topThree.length > 1)
                _buildPodiumItem(topThree[1], 2, _DesignColors.silver, 80),
              // 1ère place
              if (topThree.isNotEmpty)
                _buildPodiumItem(topThree[0], 1, _DesignColors.gold, 100),
              // 3ème place
              if (topThree.length > 2)
                _buildPodiumItem(topThree[2], 3, _DesignColors.bronze, 60),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(ClassementPlayer player, int rank, Color color, double height) {
    final colors = context.colors;
    final userState = context.watch<UserStateProvider>();
    final isCurrentUser = player.isCurrentUser;
    
    return GestureDetector(
      onTap: () => _navigateToPlayerProfile(player.idJoueur),
      child: Column(
        children: [
          // Avatar avec couronne
          Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.5), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: rank == 1 ? 35 : 28,
                  backgroundColor: colors.cardBackground,
                  child: CircleAvatar(
                    radius: rank == 1 ? 32 : 25,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: player.avatar != null && player.avatar!.isNotEmpty
                        ? NetworkImage(player.avatar!)
                        : null,
                    child: player.avatar == null || player.avatar!.isEmpty
                        ? Icon(Icons.person, color: Colors.grey.shade400, size: rank == 1 ? 35 : 28)
                        : null,
                  ),
                ),
              ),
              // Médaille
              Positioned(
                top: -8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Nom
          SizedBox(
            width: 80,
            child: Text(
              isCurrentUser ? userState.userName : player.nom,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCurrentUser ? _DesignColors.primary : colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // XP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${isCurrentUser ? userState.pointsXP : player.xp} XP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList(List<ClassementPlayer> players, {int startRank = 4}) {
    final colors = context.colors;
    
    if (players.isEmpty) return const SizedBox.shrink();
    
    return Container(
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: players.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 70,
          color: colors.divider,
        ),
        itemBuilder: (context, index) {
          final player = players[index];
          return _buildPlayerTile(player, player.rank);
        },
      ),
    );
  }

  Widget _buildPlayerTile(ClassementPlayer player, int rank) {
    final colors = context.colors;
    final userState = context.watch<UserStateProvider>();
    final isCurrentUser = player.isCurrentUser;
    
    final String levelDisplay = isCurrentUser ? 'Stage ${userState.currentStageLevel}' : player.niveau;
    final int displayXp = isCurrentUser ? userState.pointsXP : player.xp;

    return GestureDetector(
      onTap: () => _navigateToPlayerProfile(player.idJoueur),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: isCurrentUser
            ? BoxDecoration(
                color: _DesignColors.primary.withOpacity(0.1),
                border: Border.all(color: _DesignColors.primary.withOpacity(0.3)),
              )
            : null,
        child: Row(
          children: [
            // Rank
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getRankColor(rank).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getRankColor(rank),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Avatar
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _DesignColors.primary.withOpacity(0.3),
                    _DesignColors.primary,
                  ],
                ),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: colors.cardBackground,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: player.avatar != null && player.avatar!.isNotEmpty
                      ? NetworkImage(player.avatar!)
                      : null,
                  child: player.avatar == null || player.avatar!.isEmpty
                      ? Icon(Icons.person, color: Colors.grey.shade400, size: 22)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name and level
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCurrentUser ? userState.userName : player.nom,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isCurrentUser ? _DesignColors.primary : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    levelDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // XP Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _DesignColors.primary.withOpacity(0.2),
                    _DesignColors.primary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _DesignColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, size: 14, color: _DesignColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '$displayXp',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _DesignColors.primary,
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

  Widget _buildYourPositionCard(ClassementPlayer currentUser) {
    final colors = context.colors;
    final userState = context.watch<UserStateProvider>();
    
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _DesignColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: _DesignColors.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _DesignColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_pin, color: _DesignColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Votre position',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Player tile
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _DesignColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '#${currentUser.rank}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _DesignColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Avatar
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _DesignColors.primary.withOpacity(0.5),
                        _DesignColors.primary,
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: colors.cardBackground,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: userState.avatarUrl != null
                          ? NetworkImage(userState.avatarUrl!)
                          : null,
                      child: userState.avatarUrl == null
                          ? Icon(Icons.person, color: Colors.grey.shade400, size: 24)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userState.userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Stage ${userState.currentStageLevel}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // XP
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_DesignColors.primary, Color(0xFFFF9800)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _DesignColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${userState.pointsXP}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return _DesignColors.gold;
      case 2:
        return _DesignColors.silver;
      case 3:
        return _DesignColors.bronze;
      default:
        return _DesignColors.secondary;
    }
  }
}
