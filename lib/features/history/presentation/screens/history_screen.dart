import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _history = [];
  bool _loading = true;
  
  // Stats calculées
  int _totalParties = 0;
  int _totalXP = 0;
  int _totalCoins = 0;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.resultsHistory)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final history = data['data'] ?? [];
        
        // Calculer les stats
        int xp = 0;
        int coins = 0;
        for (var item in history) {
          xp += (item['xpGagne'] ?? 0) as int;
          coins += (item['coinsGagnes'] ?? 0) as int;
        }
        
        setState(() {
          _history = history;
          _totalParties = history.length;
          _totalXP = xp;
          _totalCoins = coins;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
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
                const AppHeader(
                  title: 'Historique Quiz',
                  centerTitle: true,
                ),
                
                // Stats résumé
                _buildStatsRow(),
                
                const SizedBox(height: 12),
                
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFB74D),
                          ),
                        )
                      : _history.isEmpty
                          ? _buildEmptyState()
                          : _buildHistoryList(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.sports_esports,
            value: _totalParties.toString(),
            label: 'Parties',
            color: const Color(0xFF9C27B0),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.shade200,
          ),
          _buildStatItem(
            icon: Icons.bolt,
            value: _totalXP.toString(),
            label: 'XP gagnés',
            color: const Color(0xFFFFB74D),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.shade200,
          ),
          _buildStatItem(
            icon: Icons.monetization_on,
            value: _totalCoins.toString(),
            label: 'Coins',
            color: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: context.colors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
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
                color: const Color(0xFF9C27B0).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                size: 48,
                color: Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucune partie jouée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Lancez-vous dans un quiz pour voir votre historique !',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    // Regrouper par date
    Map<String, List<dynamic>> grouped = {};
    for (var item in _history) {
      final date = DateTime.tryParse(item['dateFin'] ?? item['datePartie'] ?? '') ?? DateTime.now();
      final key = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      grouped.putIfAbsent(key, () => []).add(item);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return RefreshIndicator(
      onRefresh: _fetchHistory,
      color: const Color(0xFFFFB74D),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: sortedKeys.length,
        itemBuilder: (context, idx) {
          final date = sortedKeys[idx];
          final items = grouped[date]!;
          return _buildDateSection(date, items);
        },
      ),
    );
  }

  Widget _buildDateSection(String date, List<dynamic> items) {
    // Formatter la date
    final parts = date.split('-');
    final formattedDate = _formatDateLabel(parts);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Color(0xFF9C27B0),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9C27B0),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length} partie${items.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _HistoryCard(data: item)).toList(),
        const SizedBox(height: 8),
      ],
    );
  }

  String _formatDateLabel(List<String> parts) {
    if (parts.length != 3) return parts.join('-');
    
    final day = int.tryParse(parts[0]) ?? 1;
    final month = int.tryParse(parts[1]) ?? 1;
    final year = int.tryParse(parts[2]) ?? 2025;
    
    final now = DateTime.now();
    final dateObj = DateTime(year, month, day);
    final diff = now.difference(dateObj).inDays;
    
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return "Hier";
    if (diff < 7) return "Il y a $diff jours";
    
    final months = [
      '', 'Janv', 'Févr', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'
    ];
    return '$day ${months[month]} $year';
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HistoryCard({required this.data});
  
  @override
  Widget build(BuildContext context) {
    final mode = data['modeJeu'] ?? '';
    final adversaire = data['nomAdversaire'] ?? '';
    final xp = data['xpGagne'] ?? 0;
    final coins = data['coinsGagnes'] ?? 0;
    final avatar = data['avatarAdversaire'];
    final bonnesReponses = data['bonnesReponses'] ?? 0;
    final totalQuestions = data['totalQuestions'] ?? 10;
    final niveauStage = data['niveauStage'];
    
    // Infos mode
    final modeInfo = _getModeInfo(mode, adversaire, niveauStage);
    final isVictory = bonnesReponses >= (totalQuestions / 2);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar/Icon avec bordure colorée
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  modeInfo.color.withOpacity(0.5),
                  modeInfo.color,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: modeInfo.color.withOpacity(0.1),
                backgroundImage: avatar != null && avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : null,
                child: avatar == null || avatar.isEmpty
                    ? Icon(modeInfo.icon, color: modeInfo.color, size: 26)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 14),
          
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        modeInfo.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3436),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isVictory 
                            ? const Color(0xFF4CAF50).withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isVictory ? Icons.check_circle : Icons.cancel,
                            size: 12,
                            color: isVictory ? const Color(0xFF4CAF50) : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$bonnesReponses/$totalQuestions',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isVictory ? const Color(0xFF4CAF50) : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mode badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: modeInfo.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        modeInfo.badge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: modeInfo.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Rewards
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (xp > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB74D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 14, color: Color(0xFFFFB74D)),
                      const SizedBox(width: 2),
                      Text(
                        '+$xp',
                        style: const TextStyle(
                          color: Color(0xFFFFB74D),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              if (coins > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on, size: 14, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 2),
                      Text(
                        '+$coins',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  _ModeInfo _getModeInfo(String mode, String adversaire, int? niveauStage) {
    final modeLower = mode.toLowerCase();
    
    if (modeLower.contains('défi') || modeLower.contains('duel')) {
      return _ModeInfo(
        title: 'Duel vs ${adversaire.isNotEmpty ? adversaire : 'Joueur'}',
        badge: 'DUEL',
        icon: Icons.sports_mma,
        color: const Color(0xFFE91E63),
      );
    } else if (modeLower.contains('challenge')) {
      return _ModeInfo(
        title: 'Challenge ${adversaire.isNotEmpty ? adversaire : ''}',
        badge: 'CHALLENGE',
        icon: Icons.flag,
        color: const Color(0xFF00BCD4),
      );
    } else if (modeLower.contains('stage')) {
      return _ModeInfo(
        title: 'Stage ${niveauStage ?? ''}',
        badge: 'STAGE',
        icon: Icons.stairs,
        color: const Color(0xFF9C27B0),
      );
    } else if (modeLower.contains('fiesta')) {
      return _ModeInfo(
        title: 'Mode Fiesta',
        badge: 'FIESTA',
        icon: Icons.celebration,
        color: const Color(0xFFFF9800),
      );
    } else {
      return _ModeInfo(
        title: mode.isNotEmpty ? mode : 'Quiz',
        badge: 'QUIZ',
        icon: Icons.quiz,
        color: const Color(0xFFFFB74D),
      );
    }
  }
}

class _ModeInfo {
  final String title;
  final String badge;
  final IconData icon;
  final Color color;
  
  _ModeInfo({
    required this.title,
    required this.badge,
    required this.icon,
    required this.color,
  });
}
