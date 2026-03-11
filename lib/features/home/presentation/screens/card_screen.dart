import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../quiz/presentation/screens/game_screen.dart';
import 'home_screen.dart';

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

/// Couleurs du design (identiques à profile_screen)
class _DesignColors {
  static const Color primary = Color(0xFFFFB74D);      // Orange principal
  static const Color secondary = Color(0xFF9C27B0);    // Violet
  static const Color cyan = Color(0xFF00BCD4);         // Cyan
  static const Color green = Color(0xFF4CAF50);        // Vert
  static const Color pink = Color(0xFFE91E63);         // Rose
  static const Color textDark = Color(0xFF2D3436);     // Texte foncé
  static const Color textMuted = Color(0xFF636E72);    // Texte atténué
}

/// Écran de sélection des centres d'intérêt (catégories)
/// Premier écran affiché après la connexion pour personnaliser l'expérience
class CardScreen extends StatefulWidget {
  final String userName;
  final String userLevel;
  final int userPoints;
  final int userLives;
  final String? avatarUrl;
  final String? token;

  const CardScreen({
    super.key,
    required this.userName,
    this.userLevel = 'Stage 1',
    this.userPoints = 0,
    this.userLives = 5,
    this.avatarUrl,
    this.token,
  });

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;
  final Set<int> _selectedCategories = {};

  // Couleurs pour chaque catégorie
  final List<Color> _categoryColors = [
    _DesignColors.primary,
    _DesignColors.secondary,
    _DesignColors.cyan,
    _DesignColors.green,
    _DesignColors.pink,
    const Color(0xFF607D8B),
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Color _getCategoryColor(int index) {
    return _categoryColors[index % _categoryColors.length];
  }

  /// Charger les catégories depuis l'API
  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.categories)),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
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
        debugPrint('Catégories chargées: ${_categories.length}');
      } else {
        throw Exception('Erreur lors du chargement des catégories');
      }
    } catch (e) {
      debugPrint('Erreur catégories: $e');
      setState(() {
        _error = 'Impossible de charger les catégories';
        _isLoading = false;
        // Données de test en cas d'erreur réseau
        _categories = [
          Category(
            idCategorie: 1,
            nom: 'Géographie',
            icone: '🌍',
            sousCategories: [
              SubCategory(idSousCategorie: 1, nom: 'Capitales'),
              SubCategory(idSousCategorie: 2, nom: 'Continents'),
            ],
          ),
          Category(
            idCategorie: 2,
            nom: 'Histoire',
            icone: '📚',
            sousCategories: [
              SubCategory(idSousCategorie: 3, nom: 'Préhistoire'),
              SubCategory(idSousCategorie: 4, nom: 'Histoire africaine'),
            ],
          ),
          Category(idCategorie: 3, nom: 'Arts', icone: '🎨'),
          Category(idCategorie: 4, nom: 'Science', icone: '🔬'),
          Category(idCategorie: 5, nom: 'Biologie', icone: '🧬'),
          Category(idCategorie: 6, nom: 'Politique', icone: '⚖️'),
        ];
      });
    }
  }

  void _onCategorySelected(Category category) {
    setState(() {
      if (_selectedCategories.contains(category.idCategorie)) {
        _selectedCategories.remove(category.idCategorie);
      } else {
        _selectedCategories.add(category.idCategorie);
      }
    });
  }

  Future<void> _navigateToHome() async {
    // 🔐 Sauvegarder les catégories sélectionnées
    await SessionService.instance.saveSelectedCategories(_selectedCategories.toList());

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          userName: widget.userName,
          userLevel: widget.userLevel,
          userPoints: widget.userPoints,
          userLives: widget.userLives,
          avatarUrl: widget.avatarUrl,
          token: widget.token,
          selectedCategoryIds: _selectedCategories.toList(),
        ),
      ),
    );
  }

  void _showAllCategories() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('Toutes les catégories sont affichées'),
          ],
        ),
        backgroundColor: _DesignColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
                // Header (mode complet comme home_screen)
                const AppHeader(),
                
                const SizedBox(height: 16),
                
                // Stats Card
                _buildStatsCard(),
                
                const SizedBox(height: 16),
                
                // Section title
                _buildSectionTitle(),
                
                // Categories Grid
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _DesignColors.primary),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCategories,
                          color: _DesignColors.primary,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(20),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              return _buildCategoryCard(category, index);
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(
        currentIndex: 1,
      ),
    );
  }

  Widget _buildStatsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Categories count
            Expanded(
              child: _buildMiniStatCard(
                'Catégories',
                '${_categories.length}',
                Icons.category,
                _DesignColors.secondary,
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.grey.shade200,
            ),
            // Niveau
            Expanded(
              child: _buildMiniStatCard(
                'Niveau',
                widget.userLevel,
                Icons.trending_up,
                _DesignColors.green,
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.grey.shade200,
            ),
            // XP
            Expanded(
              child: _buildMiniStatCard(
                'XP',
                '${widget.userPoints}',
                Icons.bolt,
                _DesignColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color) {
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _DesignColors.textDark,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
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

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Toutes les catégories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _DesignColors.textDark,
            ),
          ),
          GestureDetector(
            onTap: _showAllCategories,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _DesignColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Text(
                    'Voir tout',
                    style: TextStyle(
                      color: _DesignColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: _DesignColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Category category, int index) {
    final id = category.idCategorie;
    final isSelected = _selectedCategories.contains(id);
    final color = _getCategoryColor(index);

    return GestureDetector(
      onTap: () {
        // Si la catégorie a des sous-catégories, afficher un dialog
        if (category.sousCategories != null && category.sousCategories!.isNotEmpty) {
          _showSubCategoryDialog(category, color);
        } else {
          // Sinon, lancer directement le jeu
          _startGame(category.idCategorie, category.nom);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
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
            // Icône (style profile_screen)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  category.icone ?? '📚',
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(height: 14),
            
            // Nom catégorie
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                category.nom,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : _DesignColors.textDark,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Play button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(
                    'Jouer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            
            // Check icon if selected
            if (isSelected) ...[
              const SizedBox(height: 8),
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
            ],
            
            // Badge si sous-catégories
            if (category.sousCategories != null && category.sousCategories!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _DesignColors.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${category.sousCategories!.length} catégories',
                  style: const TextStyle(
                    fontSize: 10,
                    color: _DesignColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startGame(int categoryId, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          userName: widget.userName,
          userLevel: widget.userLevel,
          userLives: widget.userLives,
          userCoins: null,
          avatarUrl: widget.avatarUrl,
          token: widget.token,
          idCategorie: categoryId,
          categorieNom: categoryName,
          mode: 'category',
          nombreQuestions: 10,
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
                  Navigator.pop(context);
                  _startGame(subCat.idSousCategorie, subCat.nom);
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

  Widget _buildContinueButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: _navigateToHome,
          style: ElevatedButton.styleFrom(
            backgroundColor: _DesignColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            'Continuer (${_selectedCategories.length} sélectionnée${_selectedCategories.length > 1 ? 's' : ''})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}