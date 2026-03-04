import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _badges = [];
  List<dynamic> _trophees = [];
  List<dynamic> _bonus = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.myRewards)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _badges = data['data']['badges'] ?? [];
          _trophees = data['data']['trophees'] ?? [];
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  title: 'Mon Inventaire',
                  centerTitle: true,
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF9C27B0),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black54,
                  indicator: BoxDecoration(
                    color: const Color(0xFF9C27B0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tabs: const [
                    Tab(child: Text('Badges')),
                    Tab(child: Text('Trophées')),
                    Tab(child: Text('Bonus')),
                  ],
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildBadgeList(),
                            _buildTropheeList(),
                            _buildBonusList(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildBadgeList() {
    if (_badges.isEmpty) {
      return const Center(child: Text('Aucun badge'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _badges.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, idx) {
        final badge = _badges[idx];
        return ListTile(
          leading: badge['icone'] != null
              ? Image.network(badge['icone'], width: 40, height: 40)
              : const Icon(Icons.verified, size: 40),
          title: Text(badge['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(badge['description'] ?? ''),
          trailing: badge['recompenseXP'] != null && badge['recompenseXP'] > 0
              ? Text('+${badge['recompenseXP']}XP', style: const TextStyle(color: Color(0xFF9C27B0), fontWeight: FontWeight.bold))
              : null,
        );
      },
    );
  }

  Widget _buildTropheeList() {
    if (_trophees.isEmpty) {
      return const Center(child: Text('Aucun trophée'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _trophees.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, idx) {
        final trophee = _trophees[idx];
        return ListTile(
          leading: trophee['icone'] != null
              ? Image.network(trophee['icone'], width: 40, height: 40)
              : const Icon(Icons.emoji_events, size: 40),
          title: Text(trophee['nom'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(trophee['description'] ?? ''),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (trophee['xp'] != null && trophee['xp'] > 0)
                Text('+${trophee['xp']}XP', style: const TextStyle(color: Color(0xFF9C27B0), fontWeight: FontWeight.bold)),
              if (trophee['coins'] != null && trophee['coins'] > 0)
                Text('+${trophee['coins']} Coins', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBonusList() {
    return const Center(child: Text('Aucun bonus'));
  }
}
