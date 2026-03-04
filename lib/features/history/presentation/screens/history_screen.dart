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
                AppHeader(
                  title: 'Historique des Quizz',
                  onBackTap: () => Navigator.of(context).pop(),
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
    final mode = data['modeJeu'] ?? data['statut'] ?? '';
    final adversaire = data['adversaire'] ?? data['nomAdversaire'] ?? '';
    final xp = data['xpGagne'] ?? data['xp'] ?? 0;
    final coins = data['coinsGagnes'] ?? data['coins'] ?? 0;
    final avatar = data['avatarAdversaire'] ?? null;
    final score = data['score'] ?? null;
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
        child: avatar == null ? const Icon(Icons.person) : null,
      ),
      title: Text(
        mode.toString().toLowerCase().contains('duel')
            ? 'Duel contre $adversaire'
            : mode.toString().toLowerCase().contains('challenge')
                ? 'Challenge ${adversaire.isNotEmpty ? adversaire : ''}'
                : 'Mode ${mode ?? ''}${score != null ? '-Stage $score' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (xp != 0) Text('+$xp XP', style: const TextStyle(color: Color(0xFF9C27B0), fontWeight: FontWeight.bold)),
          if (coins != 0) Text('+$coins Coins', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
