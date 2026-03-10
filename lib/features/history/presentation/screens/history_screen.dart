import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
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
        setState(() {
          _history = data['data'] ?? [];
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
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/backgrounds/img.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const AppHeader(
                  title: 'Historique des Quizz',
                  centerTitle: true,
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _history.isEmpty
                          ? const Center(child: Text('Aucun historique'))
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

  Widget _buildHistoryList() {
    // Regrouper par date (ex: 10-10-2025)
    Map<String, List<dynamic>> grouped = {};
    for (var item in _history) {
      final date = DateTime.tryParse(item['dateFin'] ?? item['datePartie'] ?? '') ?? DateTime.now();
      final key = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      grouped.putIfAbsent(key, () => []).add(item);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      itemCount: sortedKeys.length,
      itemBuilder: (context, idx) {
        final date = sortedKeys[idx];
        final items = grouped[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(date, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            ),
            ...items.map((item) => _HistoryCard(data: item)).toList(),
          ],
        );
      },
    );
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
    
    // Construire le titre selon le mode
    String titre;
    if (mode.toLowerCase().contains('défi') || mode.toLowerCase().contains('duel')) {
      titre = 'Duel contre ${adversaire.isNotEmpty ? adversaire : 'Joueur'}';
    } else if (mode.toLowerCase().contains('challenge')) {
      titre = 'Challenge ${adversaire.isNotEmpty ? adversaire : ''}';
    } else if (mode.toLowerCase().contains('stage')) {
      titre = 'Mode Stage${niveauStage != null ? '-Stage $niveauStage' : ''}';
    } else {
      titre = 'Mode ${mode.isNotEmpty ? mode : 'Quiz'}';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: avatar != null && avatar.isNotEmpty
                ? NetworkImage(avatar)
                : null,
            child: avatar == null || avatar.isEmpty
                ? Icon(
                    mode.toLowerCase().contains('stage') 
                        ? Icons.emoji_events 
                        : Icons.person,
                    color: Colors.grey.shade400,
                    size: 28,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          
          // Titre
          Expanded(
            child: Text(
              titre,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // XP et Coins/Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (xp > 0)
                Text(
                  '+${xp}XP',
                  style: const TextStyle(
                    color: Color(0xFFFFB300), // Jaune/Orange
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 2),
              if (coins > 0)
                Text(
                  '+${coins}Coins',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                )
              else if (mode.toLowerCase().contains('stage'))
                Text(
                  '$bonnesReponses/$totalQuestions',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
