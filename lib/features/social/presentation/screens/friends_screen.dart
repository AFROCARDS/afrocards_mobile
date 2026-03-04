import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<dynamic> _friends = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.friendsToChallenge)),
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
      setState(() => _loading = false);
    }
  }

  Future<void> _searchFriends(String query) async {
    if (query.isEmpty) {
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
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl('/social/search-friends?query=$query')),
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
    } catch (_) {}
    setState(() => _searching = false);
  }

  Future<void> _addFriend(int userId) async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.buildUrl('/social/friends/$userId/add')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande envoyée !')),
        );
        _searchFriends(_searchController.text);
        _fetchFriends();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'ajout.')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur réseau.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter des amis'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un joueur...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchFriends(_searchController.text),
                ),
              ),
              onSubmitted: _searchFriends,
            ),
          ),
          if (_searching) const LinearProgressIndicator(),
          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults()
                : _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildFriendsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return const Center(child: Text('Aucun ami pour le moment.'));
    }
    return ListView.builder(
      itemCount: _friends.length,
      itemBuilder: (context, idx) {
        final friend = _friends[idx];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: friend['avatar'] != null
                ? NetworkImage(friend['avatar'])
                : null,
            child: friend['avatar'] == null ? const Icon(Icons.person) : null,
          ),
          title: Text(friend['pseudo'] ?? 'Joueur'),
          subtitle: Text(friend['email'] ?? ''),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text('Aucun résultat.'));
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, idx) {
        final user = _searchResults[idx];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user['avatar'] != null
                ? NetworkImage(user['avatar'])
                : null,
            child: user['avatar'] == null ? const Icon(Icons.person_add) : null,
          ),
          title: Text(user['pseudo'] ?? 'Joueur inconnu'),
          subtitle: Text(user['email'] ?? ''),
          trailing: IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Colors.green),
            onPressed: () => _addFriend(user['id']),
          ),
        );
      },
    );
  }
}
