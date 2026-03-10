import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _friends = [];
  List<dynamic> _pendingRequests = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _searching = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFriends();
    _fetchPendingRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFriends() async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.amis)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _friends = data['data'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Erreur fetch amis: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchPendingRequests() async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.amisDemandesRecues)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pendingRequests = data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Erreur fetch demandes: $e');
    }
  }

  Future<void> _searchPlayers(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    try {
      final url = '${ApiEndpoints.buildUrl(ApiEndpoints.rechercherJoueurs)}?pseudo=$query';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchResults = data['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Erreur recherche: $e');
    }
    setState(() => _searching = false);
  }

  Future<void> _sendFriendRequest(int idJoueur) async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.amisDemande)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'idJoueur': idJoueur}),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande d\'ami envoyée !'), backgroundColor: Colors.green),
        );
        _searchPlayers(_searchController.text);
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Erreur'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur réseau'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _acceptRequest(int idAmitie) async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    try {
      final response = await http.put(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.amisAccepter(idAmitie))),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande acceptée !'), backgroundColor: Colors.green),
        );
        _fetchFriends();
        _fetchPendingRequests();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectRequest(int idAmitie) async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    try {
      final response = await http.put(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.amisRefuser(idAmitie))),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande refusée'), backgroundColor: Colors.orange),
        );
        _fetchPendingRequests();
      }
    } catch (e) {
      debugPrint('Erreur refus: $e');
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
                const AppHeader(title: 'Amis', centerTitle: true),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un joueur...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _searchPlayers(_searchController.text),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        setState(() => _searchResults = []);
                      }
                    },
                    onSubmitted: _searchPlayers,
                  ),
                ),
                if (_searching) const LinearProgressIndicator(),
                // Tabs for Friends and Pending Requests
                if (_searchResults.isEmpty)
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF9C27B0),
                    labelColor: const Color(0xFF9C27B0),
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Mes amis (${_friends.length})'),
                      Tab(text: 'Demandes (${_pendingRequests.length})'),
                    ],
                  ),
                Expanded(
                  child: _searchResults.isNotEmpty
                      ? _buildSearchResults()
                      : _loading
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildFriendsList(),
                                _buildPendingRequestsList(),
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

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Aucun ami pour le moment', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Recherchez des joueurs pour ajouter des amis !', style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchFriends,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _friends.length,
        itemBuilder: (context, idx) {
          final friend = _friends[idx];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    friendId: friend['idJoueur'] ?? friend['id'],
                    friendName: friend['pseudo'] ?? 'Joueur',
                    friendAvatar: friend['avatarURL'],
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: friend['avatarURL'] != null ? NetworkImage(friend['avatarURL']) : null,
                    child: friend['avatarURL'] == null ? const Icon(Icons.person, color: Colors.grey, size: 30) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(friend['pseudo'] ?? 'Joueur', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                        const SizedBox(height: 2),
                        Text('Stage ${friend['niveauStage'] ?? 1}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Text('${friend['totalXP'] ?? 0}XP', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF9C27B0))),
                  const SizedBox(width: 8),
                  const Icon(Icons.chat_bubble_outline, color: Colors.grey),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingRequestsList() {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Aucune demande en attente', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchPendingRequests,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, idx) {
          final request = _pendingRequests[idx];
          final demandeur = request['demandeur'] ?? {};
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: demandeur['avatarURL'] != null ? NetworkImage(demandeur['avatarURL']) : null,
                  child: demandeur['avatarURL'] == null ? const Icon(Icons.person, color: Colors.grey, size: 30) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(demandeur['pseudo'] ?? 'Joueur', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                      Text('${demandeur['totalXP'] ?? 0}XP', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                  onPressed: () => _acceptRequest(request['idAmitie']),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                  onPressed: () => _rejectRequest(request['idAmitie']),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text('Aucun résultat.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, idx) {
        final user = _searchResults[idx];
        final statut = user['statut'] ?? 'inconnu';
        
        Widget? trailingWidget;
        if (statut == 'accepte') {
          trailingWidget = const Chip(
            label: Text('Ami', style: TextStyle(color: Colors.white, fontSize: 12)),
            backgroundColor: Colors.green,
          );
        } else if (statut == 'en_attente') {
          trailingWidget = const Chip(
            label: Text('En attente', style: TextStyle(color: Colors.white, fontSize: 12)),
            backgroundColor: Colors.orange,
          );
        } else {
          trailingWidget = IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF9C27B0)),
            onPressed: () => _sendFriendRequest(user['idJoueur']),
          );
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[200],
                backgroundImage: user['avatarURL'] != null ? NetworkImage(user['avatarURL']) : null,
                child: user['avatarURL'] == null ? const Icon(Icons.person, color: Colors.grey, size: 30) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['pseudo'] ?? 'Joueur', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                    Text('${user['totalXP'] ?? 0}XP - Niveau ${user['niveau'] ?? 1}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
              trailingWidget,
            ],
          ),
        );
      },
    );
  }
}
