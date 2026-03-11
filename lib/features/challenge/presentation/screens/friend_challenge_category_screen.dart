import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../quiz/presentation/screens/game_screen.dart';

/// Modèle pour Catégorie
class Category {
  final int idCategorie;
  final String nom;
  final String? description;
  final String? icone;
  final List<SubCategory>? sousCategories;

  Category({
    required this.idCategorie,
    required this.nom,
    this.description,
    this.icone,
    this.sousCategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    List<SubCategory>? subs;
    if (json['sousCategories'] != null) {
      subs = List<SubCategory>.from(
        (json['sousCategories'] as List).map((x) => SubCategory.fromJson(x))
      );
    }
    return Category(
      idCategorie: json['idCategorie'] ?? json['id'] ?? 0,
      nom: json['nom'] ?? '',
      description: json['description'],
      icone: json['icone'],
      sousCategories: subs,
    );
  }
}

/// Modèle pour Sous-Catégorie
class SubCategory {
  final int idSousCategorie;
  final String nom;
  final String? description;
  final String? icone;

  SubCategory({
    required this.idSousCategorie,
    required this.nom,
    this.description,
    this.icone,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      idSousCategorie: json['idSousCategorie'] ?? json['id'] ?? 0,
      nom: json['nom'] ?? '',
      description: json['description'],
      icone: json['icone'],
    );
  }
}

/// Écran de sélection de catégorie/sous-catégorie pour défi entre amis
class FriendChallengeCategoryScreen extends StatefulWidget {
  final String? token;
  final int friendId;
  final String friendName;
  final int coinsBet;
  final int questionCount;

  const FriendChallengeCategoryScreen({
    super.key,
    this.token,
    required this.friendId,
    required this.friendName,
    required this.coinsBet,
    required this.questionCount,
  });

  @override
  State<FriendChallengeCategoryScreen> createState() =>
      _FriendChallengeCategoryScreenState();
}

class _FriendChallengeCategoryScreenState
    extends State<FriendChallengeCategoryScreen> {
  List<Category> _categories = [];
  bool _isLoading = true;
  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.categories)),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> categoriesList = data['data'] ?? [];
        
        setState(() {
          _categories = categoriesList
              .map((cat) => Category.fromJson(cat))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Erreur chargement catégories: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startChallenge() {
    if (_selectedCategory == null) return;

    final userState = context.read<UserStateProvider>();
    
    // Utiliser la sous-catégorie si disponible, sinon la catégorie
    final categoryId = _selectedSubCategory?.idSousCategorie ?? 
                      _selectedCategory!.idCategorie;
    final categoryName = _selectedSubCategory?.nom ?? 
                        _selectedCategory!.nom;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          userName: userState.userName,
          userLevel: userState.userLevel,
          userLives: userState.lives,
          userCoins: userState.coins,
          avatarUrl: userState.avatarUrl,
          token: widget.token,
          mode: 'friend_challenge',
          nombreQuestions: widget.questionCount,
          opponentName: widget.friendName,
          opponentId: widget.friendId,
          coinsBet: widget.coinsBet,
          idCategorie: categoryId,
          categorieNom: categoryName,
        ),
      ),
    );
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
                AppHeader(
                  title: 'Choisir une Catégorie',
                  onBackTap: () => Navigator.of(context).pop(),
                  centerTitle: true,
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _categories.isEmpty
                          ? const Center(
                              child: Text('Aucune catégorie disponible'))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Infos du défi
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: colors.cardBackground,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFFFB74D),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Défier: ${widget.friendName}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFFB74D),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Questions: ${widget.questionCount}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            Text(
                                              'Mise: ${widget.coinsBet} 🪙',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Sélectionner une catégorie:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._categories.map((category) => 
                                    _buildCategoryTile(context, colors, category)
                                  ).toList(),
                                ],
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedCategory != null
          ? Container(
              color: colors.cardBackground,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _startChallenge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB74D),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Démarrer le Défi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    ThemeColors colors,
    Category category,
  ) {
    final isSelected = _selectedCategory?.idCategorie == category.idCategorie;
    
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedCategory = null;
                _selectedSubCategory = null;
              } else {
                _selectedCategory = category;
                _selectedSubCategory = null;
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFFFFB74D).withOpacity(0.2)
                  : colors.cardBackground,
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFFFFB74D)
                    : colors.cardBackground,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (category.icone != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Image.asset(
                      'assets/images/icons/${category.icone}',
                      width: 32,
                      height: 32,
                      errorBuilder: (_, __, ___) => const Icon(Icons.category),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.nom,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected 
                              ? const Color(0xFFFFB74D)
                              : Colors.black87,
                        ),
                      ),
                      if (category.description != null)
                        Text(
                          category.description!,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFFFFB74D),
                  ),
              ],
            ),
          ),
        ),
        // Sous-catégories si sélectionnées
        if (isSelected && 
            category.sousCategories != null && 
            category.sousCategories!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Spécialité:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                ...category.sousCategories!.map((subCat) =>
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSubCategory = subCat;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: _selectedSubCategory?.idSousCategorie == subCat.idSousCategorie
                            ? const Color(0xFF9C27B0).withOpacity(0.2)
                            : Colors.grey[100],
                        border: Border.all(
                          color: _selectedSubCategory?.idSousCategorie == subCat.idSousCategorie
                              ? const Color(0xFF9C27B0)
                              : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              subCat.nom,
                              style: TextStyle(
                                fontSize: 12,
                                color: _selectedSubCategory?.idSousCategorie == subCat.idSousCategorie
                                    ? const Color(0xFF9C27B0)
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (_selectedSubCategory?.idSousCategorie == subCat.idSousCategorie)
                            const Icon(
                              Icons.check,
                              size: 16,
                              color: Color(0xFF9C27B0),
                            ),
                        ],
                      ),
                    ),
                  ),
                ).toList(),
              ],
            ),
          ),
      ],
    );
  }
}
