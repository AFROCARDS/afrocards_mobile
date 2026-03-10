import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../history/presentation/screens/history_screen.dart';
import '../../../inventory/presentation/screens/inventory_screen.dart';
import '../../../social/presentation/screens/notifications_screen.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../../../social/presentation/screens/friends_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _loading = true;
  int _nombreAmis = 0;
  int _nombreTrophees = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchStats();
  }

  Future<void> _fetchProfile() async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.profile)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _profileData = data['data'];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchStats() async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    
    try {
      // Fetch nombre d'amis
      final amisResponse = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.amisCount)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (amisResponse.statusCode == 200) {
        final data = jsonDecode(amisResponse.body);
        setState(() {
          _nombreAmis = data['count'] ?? 0;
        });
      }
      
      // Fetch badges et trophées du joueur
      final inventaireResponse = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.inventaire)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (inventaireResponse.statusCode == 200) {
        final data = jsonDecode(inventaireResponse.body);
        setState(() {
          _nombreTrophees = (data['data']?['trophees'] as List?)?.length ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Erreur fetch stats: $e');
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final userState = context.read<UserStateProvider>();
              userState.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }

  String _getBadgeName(int xp) {
    if (xp >= 10000) return 'Légende';
    if (xp >= 7500) return 'Maître';
    if (xp >= 5000) return 'Diamant';
    if (xp >= 3000) return 'Platine';
    if (xp >= 2000) return 'Or';
    if (xp >= 1000) return 'Argent';
    if (xp >= 500) return 'Bronze';
    if (xp >= 100) return 'Débutant';
    return 'Novice';
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserStateProvider>();
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
                  title: 'Profil',
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      onPressed: _logout,
                      tooltip: 'Déconnexion',
                    ),
                  ],
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _profileData == null
                          ? const Center(child: Text('Erreur de chargement du profil'))
                          : _buildProfileContent(userState),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildProfileContent(UserStateProvider userState) {
    final profil = _profileData?['profil'] ?? {};
    final utilisateur = _profileData?['utilisateur'] ?? {};
    final totalXP = profil['pointsXP'] ?? userState.pointsXP;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: userState.avatarUrl != null
                    ? NetworkImage(userState.avatarUrl!)
                    : null,
                child: userState.avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white, size: 50)
                    : null,
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 20),
                    onPressed: () {}, // TODO: Ajout modification avatar
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            profil['pseudo'] ?? userState.userName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getBadgeName(totalXP),
              style: const TextStyle(color: Color(0xFF9C27B0), fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatCard(label: 'XP', value: totalXP.toString()),
              const SizedBox(width: 16),
              _StatCard(label: 'Trophées', value: _nombreTrophees.toString()),
              const SizedBox(width: 16),
              _StatCard(label: 'Ami(e)s', value: _nombreAmis.toString()),
            ],
          ),
          const SizedBox(height: 24),
          _ProfileMenuSection(
            items: [
              _ProfileMenuItem(
                title: 'Ajouter des amis',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const FriendsScreen()),
                  );
                },
              ),
              _ProfileMenuItem(
                title: 'Historique Quizz',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  );
                },
              ),
              _ProfileMenuItem(
                title: 'Portefeuille',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const WalletScreen()),
                  );
                },
              ),
              _ProfileMenuItem(
                title: 'Mon Inventaire',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const InventoryScreen()),
                  );
                },
              ),
              _ProfileMenuItem(
                title: 'Notifications',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ProfileMenuSection(
            title: 'Général',
            items: [
              _ProfileMenuItem(
                title: 'Chat',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FriendsScreen(),
                    ),
                  );
                },
              ),
              const _ProfileMenuItem(title: 'Préférences'),
              const _ProfileMenuItem(title: 'Réglages'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _ProfileMenuSection extends StatelessWidget {
  final String? title;
  final List<_ProfileMenuItem> items;
  const _ProfileMenuSection({this.title, required this.items});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 6),
            child: Text(title!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const _ProfileMenuItem({required this.title, this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}
