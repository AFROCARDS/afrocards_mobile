import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../quiz/presentation/screens/game_screen.dart';

/// Couleurs du design (identiques à CardScreen)
class _DesignColors {
  static const Color primary = Color(0xFFFFB74D);      // Orange principal
  static const Color secondary = Color(0xFF9C27B0);    // Violet
  static const Color cyan = Color(0xFF00BCD4);         // Cyan
  static const Color green = Color(0xFF4CAF50);        // Vert
  static const Color pink = Color(0xFFE91E63);         // Rose
  static const Color textDark = Color(0xFF2D3436);     // Texte foncé
  static const Color textMuted = Color(0xFF636E72);    // Texte atténué
}

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

  // Couleurs pour chaque catégorie
  final List<Color> _categoryColors = [
    _DesignColors.primary,
    _DesignColors.secondary,
    _DesignColors.cyan,
    _DesignColors.green,
    _DesignColors.pink,
    const Color(0xFF607D8B),
  ];

  Color _getCategoryColor(int index) {
    return _categoryColors[index % _categoryColors.length];
  }

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
                      ? const Center(child: CircularProgressIndicator(color: _DesignColors.primary))
                      : _categories.isEmpty
                          ? const Center(child: Text('Aucune catégorie disponible'))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Infos du défi
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: colors.cardBackground,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _DesignColors.primary,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _DesignColors.primary.withOpacity(0.1),
                                          blurRadius: 15,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: _DesignColors.primary.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.sports_esports,
                                                color: _DesignColors.primary,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Défier ${widget.friendName}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: _DesignColors.primary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: _DesignColors.secondary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.help_outline, size: 14, color: _DesignColors.secondary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${widget.questionCount} Q.',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: _DesignColors.secondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: _DesignColors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Text(
                                                    '🪙 ',
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                  Text(
                                                    '${widget.coinsBet}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: _DesignColors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  // GridView de catégories
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.85,
                                    ),
                                    itemCount: _categories.length,
                                    itemBuilder: (context, index) {
                                      return _buildCategoryCard(
                                        context,
                                        colors,
                                        _categories[index],
                                        index,
                                      );
                                    },
                                  ),
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
                  backgroundColor: _DesignColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
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
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    ThemeColors colors,
    Category category,
    int index,
  ) {
    final isSelected = _selectedCategory?.idCategorie == category.idCategorie;
    final color = _getCategoryColor(index);

    return GestureDetector(
      onTap: () {
        // Si la catégorie a des sous-catégories, afficher un dialog
        if (category.sousCategories != null && category.sousCategories!.isNotEmpty) {
          _showSubCategoryDialog(category, color);
        } else {
          // Sinon, sélectionner directement
          setState(() {
            if (isSelected) {
              _selectedCategory = null;
              _selectedSubCategory = null;
            } else {
              _selectedCategory = category;
              _selectedSubCategory = null;
            }
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? color.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône circulaire
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  category.icone ?? '📚',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Nom catégorie
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                category.nom,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : _DesignColors.textDark,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Badge si sous-catégories
            if (category.sousCategories != null && category.sousCategories!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _DesignColors.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${category.sousCategories!.length} spécialités',
                  style: const TextStyle(
                    fontSize: 9,
                    color: _DesignColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            const SizedBox(height: 8),
            
            // Check icon if selected
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showSubCategoryDialog(Category category, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                category.icone ?? '📚',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.nom,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _DesignColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sélectionnez une spécialité',
                    style: TextStyle(
                      fontSize: 12,
                      color: _DesignColors.textMuted,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...category.sousCategories!.map((subCat) => GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                    _selectedSubCategory = subCat;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subCat.nom,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: _DesignColors.textDark,
                              ),
                            ),
                            if (subCat.description != null && subCat.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                subCat.description!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _DesignColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: color,
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fermer',
              style: TextStyle(color: _DesignColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
