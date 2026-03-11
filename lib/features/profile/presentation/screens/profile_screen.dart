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
import 'edit_profile_screen.dart';

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
    if (token == null) {
      debugPrint('❌ [Profile] Token is null');
      return;
    }
    try {
      final url = ApiEndpoints.buildUrl(ApiEndpoints.profile);
      debugPrint('🔍 [Profile] Fetching: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      debugPrint('🔍 [Profile] Status: ${response.statusCode}');
      debugPrint('🔍 [Profile] Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('🔍 [Profile] Data keys: ${data.keys}');
        debugPrint('🔍 [Profile] data[data] keys: ${data['data']?.keys}');
        debugPrint('🔍 [Profile] badgePrincipal: ${data['data']?['badgePrincipal']}');
        setState(() {
          _profileData = data['data'];
          _loading = false;
        });
      } else {
        debugPrint('❌ [Profile] Error status: ${response.statusCode}');
        setState(() => _loading = false);
      }
    } catch (e, stack) {
      debugPrint('❌ [Profile] Exception: $e');
      debugPrint('❌ [Profile] Stack: $stack');
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchStats() async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    
    try {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Déconnexion'),
          ],
        ),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final userState = context.read<UserStateProvider>();
              userState.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
    if (result == true) {
      _fetchProfile();
      _fetchStats();
    }
  }

  String _getBadgeName() {
    final badge = _profileData?['badgePrincipal'];
    if (badge != null && badge['nom'] != null) {
      return badge['nom'];
    }
    return 'Novice';
  }

  Color _getBadgeColor() {
    final badge = _profileData?['badgePrincipal'];
    if (badge != null && badge['couleur'] != null) {
      String colorStr = badge['couleur'].toString();
      if (colorStr.startsWith('#')) {
        colorStr = colorStr.substring(1);
      }
      return Color(int.parse('FF$colorStr', radix: 16));
    }
    return const Color(0xFF78909C);
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
                // Header (mode complet comme home_screen)
                const AppHeader(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFB74D)))
                      : _profileData == null
                          ? _buildErrorState()
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

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
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
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Impossible de charger le profil',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _loading = true);
                _fetchProfile();
                _fetchStats();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB74D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(UserStateProvider userState) {
    final profil = _profileData?['profil'] ?? {};
    final totalXP = userState.pointsXP > 0 ? userState.pointsXP : (profil['pointsXP'] ?? 0);
    final bio = profil['bio'] as String?;
    final nationalite = profil['nationalite'] as String?;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // Profile Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Bouton déconnexion en haut à droite
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.logout, color: Colors.red, size: 20),
                    ),
                  ),
                ),
                // Contenu du profil
                Center(
                  child: Column(
                    children: [
                      // Avatar avec bouton modifier
                      GestureDetector(
                        onTap: _navigateToEditProfile,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    _getBadgeColor().withOpacity(0.5),
                                    _getBadgeColor(),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 52,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: userState.avatarUrl != null
                                      ? NetworkImage(userState.avatarUrl!)
                                      : null,
                                  child: userState.avatarUrl == null
                                      ? Icon(Icons.person, color: Colors.grey.shade400, size: 50)
                                      : null,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB74D),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Pseudo
                      Text(
                        profil['pseudo'] ?? userState.userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      
                      // Nationalité
                      if (nationalite != null && nationalite.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              nationalite,
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                      
                      // Bio
                      if (bio != null && bio.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          bio,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF636E72),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 12),
                      
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getBadgeColor().withOpacity(0.2),
                              _getBadgeColor().withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getBadgeColor().withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars, size: 16, color: _getBadgeColor()),
                            const SizedBox(width: 6),
                            Text(
                              _getBadgeName(),
                              style: TextStyle(
                                color: _getBadgeColor(),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
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
          ),
          
          const SizedBox(height: 16),
          
          // Stats Row
          Row(
            children: [
              Expanded(child: _buildStatCard('XP', totalXP.toString(), Icons.bolt, const Color(0xFFFFB74D))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Trophées', _nombreTrophees.toString(), Icons.emoji_events, const Color(0xFF9C27B0))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Amis', _nombreAmis.toString(), Icons.people, const Color(0xFF00BCD4))),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Menu Section
          _buildMenuSection(
            'Activité',
            [
              _MenuItemData(
                icon: Icons.people_alt,
                title: 'Mes Amis',
                color: const Color(0xFF00BCD4),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen())),
              ),
              _MenuItemData(
                icon: Icons.history,
                title: 'Historique Quiz',
                color: const Color(0xFF9C27B0),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
              ),
              _MenuItemData(
                icon: Icons.account_balance_wallet,
                title: 'Portefeuille',
                color: const Color(0xFF4CAF50),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
              ),
              _MenuItemData(
                icon: Icons.inventory_2,
                title: 'Mon Inventaire',
                color: const Color(0xFFFF9800),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Settings Section
          _buildMenuSection(
            'Paramètres',
            [
              _MenuItemData(
                icon: Icons.notifications,
                title: 'Notifications',
                color: const Color(0xFFE91E63),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
              _MenuItemData(
                icon: Icons.settings,
                title: 'Préférences',
                color: const Color(0xFF607D8B),
                onTap: () {},
              ),
            ],
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<_MenuItemData> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF2D3436),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
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
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                    ),
                    onTap: item.onTap,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 16,
                      color: Colors.grey.shade200,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  _MenuItemData({
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
  });
}
