import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';

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

/// Modèle pour un article de la boutique
class ArticleBoutique {
  final int id;
  final String nom;
  final String description;
  final int prix;
  final String? image;
  final String type;
  final int? valeur;
  final int? duree;
  final String categorie;
  final bool popular;

  ArticleBoutique({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    this.image,
    required this.type,
    this.valeur,
    this.duree,
    required this.categorie,
    this.popular = false,
  });

  factory ArticleBoutique.fromJson(Map<String, dynamic> json) {
    return ArticleBoutique(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? 'Article',
      description: json['description'] ?? '',
      prix: json['prix'] ?? 0,
      image: json['image'],
      type: json['type'] ?? 'vie',
      valeur: json['valeur'],
      duree: json['duree'],
      categorie: json['categorie'] ?? 'consommable',
      popular: json['popular'] ?? false,
    );
  }

  IconData get icon {
    switch (type) {
      case 'vie':
        return Icons.favorite;
      case 'xp_boost':
        return Icons.bolt;
      case 'coins':
        return Icons.monetization_on;
      case 'premium':
        return Icons.workspace_premium;
      case 'avatar':
        return Icons.face;
      case 'badge':
        return Icons.military_tech;
      default:
        return Icons.shopping_bag;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'vie':
        return Colors.red;
      case 'xp_boost':
        return _DesignColors.secondary;
      case 'coins':
        return _DesignColors.primary;
      case 'premium':
        return _DesignColors.pink;
      case 'avatar':
        return _DesignColors.cyan;
      case 'badge':
        return _DesignColors.green;
      default:
        return Colors.grey;
    }
  }
}

class BoutiqueScreen extends StatefulWidget {
  final String? token;
  
  const BoutiqueScreen({super.key, this.token});

  @override
  State<BoutiqueScreen> createState() => _BoutiqueScreenState();
}

class _BoutiqueScreenState extends State<BoutiqueScreen> with SingleTickerProviderStateMixin {
  List<ArticleBoutique> _articles = [];
  bool _isLoading = true;
  String? _error;
  bool _isPurchasing = false;
  late TabController _tabController;
  
  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'Tout', 'icon': Icons.apps},
    {'id': 'consommable', 'label': 'Vies', 'icon': Icons.favorite},
    {'id': 'boost', 'label': 'Boosts', 'icon': Icons.bolt},
    {'id': 'premium', 'label': 'Premium', 'icon': Icons.workspace_premium},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadArticles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    try {
      final url = ApiEndpoints.buildUrl(ApiEndpoints.boutiqueArticles);
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final articlesList = data['data'] as List? ?? [];
        setState(() {
          _articles = articlesList.map((a) => ArticleBoutique.fromJson(a)).toList();
          _isLoading = false;
          _error = null;
        });
      } else {
        throw Exception('Erreur lors du chargement des articles');
      }
    } catch (e) {
      debugPrint('Erreur chargement articles: $e');
      setState(() {
        _error = 'Impossible de charger les articles';
        _isLoading = false;
        _articles = _generateTestArticles();
      });
    }
  }

  List<ArticleBoutique> _generateTestArticles() {
    return [
      ArticleBoutique(id: 1, nom: '1 Vie', description: 'Récupérez une vie instantanément', prix: 50, type: 'vie', valeur: 1, categorie: 'consommable'),
      ArticleBoutique(id: 2, nom: 'Pack 3 Vies', description: 'Rechargez 3 vies d\'un coup', prix: 120, type: 'vie', valeur: 3, categorie: 'consommable', popular: true),
      ArticleBoutique(id: 3, nom: 'Pack 5 Vies', description: 'Rechargez toutes vos vies', prix: 180, type: 'vie', valeur: 5, categorie: 'consommable'),
      ArticleBoutique(id: 4, nom: 'Boost XP x2', description: 'Double vos gains XP pendant 30min', prix: 100, type: 'xp_boost', valeur: 2, duree: 30, categorie: 'boost'),
      ArticleBoutique(id: 5, nom: 'Boost XP x2 Pro', description: 'Double vos gains XP pendant 1 heure', prix: 180, type: 'xp_boost', valeur: 2, duree: 60, categorie: 'boost', popular: true),
      ArticleBoutique(id: 6, nom: 'Boost XP x3', description: 'Triple vos gains XP pendant 30min', prix: 200, type: 'xp_boost', valeur: 3, duree: 30, categorie: 'boost'),
      ArticleBoutique(id: 7, nom: 'Pass VIP Semaine', description: 'Vies illimitées + Boost XP permanent', prix: 500, type: 'premium', valeur: 1, duree: 10080, categorie: 'premium', popular: true),
      ArticleBoutique(id: 8, nom: 'Pass VIP Mois', description: 'Tous les avantages VIP pour 30 jours', prix: 1500, type: 'premium', valeur: 1, duree: 43200, categorie: 'premium'),
    ];
  }

  List<ArticleBoutique> _getFilteredArticles(String categoryId) {
    if (categoryId == 'all') return _articles;
    return _articles.where((a) => a.categorie == categoryId).toList();
  }

  Future<void> _acheterArticle(ArticleBoutique article) async {
    final userState = context.read<UserStateProvider>();
    
    if (userState.coins < article.prix) {
      _showMessage('Pas assez de coins ! Vous avez ${userState.coins} coins', isError: true);
      return;
    }

    final confirme = await _showPurchaseConfirmation(article, userState);
    if (confirme != true) return;

    setState(() => _isPurchasing = true);

    try {
      final token = widget.token ?? userState.token;
      
      if (token == null) {
        await _applyPurchaseLocally(article, userState);
        return;
      }

      final response = await http.post(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.boutiqueAcheter)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'articleId': article.id}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await _applyPurchaseLocally(article, userState);
        _showMessage('${data['message']} - ${data['effet']}');
      } else {
        _showMessage(data['message'] ?? 'Erreur lors de l\'achat', isError: true);
      }
    } catch (e) {
      debugPrint('Erreur achat: $e');
      await _applyPurchaseLocally(article, userState);
    } finally {
      setState(() => _isPurchasing = false);
    }
  }

  Future<bool?> _showPurchaseConfirmation(ArticleBoutique article, UserStateProvider userState) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Article icon (style profile_screen)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: article.iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(article.icon, size: 48, color: article.iconColor),
            ),
            const SizedBox(height: 16),
            
            Text(
              article.nom,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: _DesignColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            
            // Prix (style badge profile_screen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _DesignColors.primary.withOpacity(0.2),
                    _DesignColors.primary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _DesignColors.primary.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: _DesignColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '${article.prix}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: _DesignColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            Text(
              'Solde après achat: ${userState.coins - article.prix} coins',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _DesignColors.textDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _DesignColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirmer',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _applyPurchaseLocally(ArticleBoutique article, UserStateProvider userState) async {
    if (!await userState.spendCoins(article.prix)) {
      _showMessage('Pas assez de coins !', isError: true);
      return;
    }

    switch (article.type) {
      case 'vie':
        final viesToAdd = article.valeur ?? 1;
        for (int i = 0; i < viesToAdd; i++) {
          if (userState.lives < userState.maxLives) {
            userState.addLives(1);
          }
        }
        _showMessage('+${article.valeur} vie(s) ajoutée(s) !');
        break;
        
      case 'xp_boost':
        _showMessage('Boost XP x${article.valeur} activé pour ${article.duree} minutes !');
        break;
        
      case 'coins':
        await userState.addCoins(article.valeur ?? 0);
        _showMessage('+${article.valeur} coins ajoutés !');
        break;
        
      case 'premium':
        _showMessage('Pass VIP activé !');
        break;
        
      case 'avatar':
        _showMessage('Avatar "${article.nom}" débloqué !');
        break;
        
      default:
        _showMessage('Article acheté !');
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : _DesignColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
                // Header
                const AppHeader(
                  title: 'Boutique',
                  centerTitle: true,
                ),
                
                const SizedBox(height: 16),
                
                // Solde Card (style stat card profile_screen)
                _buildBalanceCard(userState),
                
                const SizedBox(height: 16),
                
                // Category Tabs
                _buildCategoryTabs(),
                
                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _DesignColors.primary),
                        )
                      : _isPurchasing
                          ? _buildPurchasingState()
                          : TabBarView(
                              controller: _tabController,
                              children: _categories.map((cat) {
                                final filteredArticles = _getFilteredArticles(cat['id']);
                                return _buildArticlesList(filteredArticles, userState);
                              }).toList(),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildHeader(UserStateProvider userState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Back button (style profile_screen)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20, color: _DesignColors.textDark),
            ),
          ),
          const SizedBox(width: 16),
          
          // Title
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boutique',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _DesignColors.textDark,
                  ),
                ),
                Text(
                  'Boostez votre progression !',
                  style: TextStyle(
                    fontSize: 13,
                    color: _DesignColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          
          // Refresh button
          GestureDetector(
            onTap: _loadArticles,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.refresh, size: 20, color: _DesignColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(UserStateProvider userState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
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
            // Coins stat (style stat card profile_screen)
            Expanded(
              child: _buildMiniStatCard(
                'Coins',
                '${userState.coins}',
                Icons.monetization_on,
                _DesignColors.primary,
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.grey.shade200,
            ),
            // Vies stat
            Expanded(
              child: _buildMiniStatCard(
                'Vies',
                '${userState.lives}/${userState.maxLives}',
                Icons.favorite,
                Colors.red,
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.grey.shade200,
            ),
            // XP stat
            Expanded(
              child: _buildMiniStatCard(
                'XP',
                '${userState.pointsXP}',
                Icons.bolt,
                _DesignColors.secondary,
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
            fontSize: 18,
            color: _DesignColors.textDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
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
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: _DesignColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          dividerColor: Colors.transparent,
          tabs: _categories.map((cat) => Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat['icon'] as IconData, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    cat['label'] as String,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildPurchasingState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
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
            const CircularProgressIndicator(color: _DesignColors.primary),
            const SizedBox(height: 20),
            const Text(
              'Achat en cours...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _DesignColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Veuillez patienter',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesList(List<ArticleBoutique> articles, UserStateProvider userState) {
    if (articles.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadArticles,
      color: _DesignColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          return _buildArticleCard(articles[index], userState);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun article',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _DesignColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cette catégorie est vide',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(ArticleBoutique article, UserStateProvider userState) {
    final canAfford = userState.coins >= article.prix;

    return GestureDetector(
      onTap: canAfford ? () => _acheterArticle(article) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: article.popular
              ? Border.all(color: _DesignColors.pink, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Icon container (style profile_screen)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: article.iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(article.icon, color: article.iconColor, size: 28),
                ),
                const SizedBox(width: 14),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _DesignColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _DesignColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (article.duree != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _DesignColors.cyan.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer_outlined, size: 12, color: _DesignColors.cyan),
                                  const SizedBox(width: 4),
                                  Text(
                                    article.duree! >= 60 
                                        ? '${(article.duree! / 60).toInt()}h'
                                        : '${article.duree}min',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _DesignColors.cyan,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Price button (style badge profile_screen)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: canAfford
                            ? LinearGradient(
                                colors: [
                                  _DesignColors.primary.withOpacity(0.2),
                                  _DesignColors.primary.withOpacity(0.1),
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey.shade200,
                                  Colors.grey.shade100,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: canAfford 
                              ? _DesignColors.primary.withOpacity(0.5) 
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on, 
                            color: canAfford ? _DesignColors.primary : Colors.grey, 
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${article.prix}',
                            style: TextStyle(
                              color: canAfford ? _DesignColors.primary : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!canAfford) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Insuffisant',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            
            // Popular badge (style profile_screen)
            if (article.popular)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _DesignColors.pink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'POPULAIRE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
