import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';

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
        return Icons.star;
      case 'avatar':
        return Icons.person;
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
        return Colors.purple;
      case 'coins':
        return Colors.amber;
      case 'premium':
        return Colors.orange;
      case 'avatar':
        return Colors.blue;
      case 'badge':
        return Colors.green;
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

class _BoutiqueScreenState extends State<BoutiqueScreen> {
  List<ArticleBoutique> _articles = [];
  bool _isLoading = true;
  String? _error;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadArticles();
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
        // Articles de test
        _articles = _generateTestArticles();
      });
    }
  }

  List<ArticleBoutique> _generateTestArticles() {
    return [
      ArticleBoutique(id: 1, nom: '1 Vie', description: 'Récupérez une vie', prix: 50, type: 'vie', valeur: 1, categorie: 'consommable'),
      ArticleBoutique(id: 2, nom: 'Pack 3 Vies', description: 'Rechargez 3 vies', prix: 120, type: 'vie', valeur: 3, categorie: 'consommable'),
      ArticleBoutique(id: 3, nom: 'Pack 5 Vies', description: 'Rechargez toutes vos vies', prix: 180, type: 'vie', valeur: 5, categorie: 'consommable'),
      ArticleBoutique(id: 4, nom: 'Boost XP x2 (30min)', description: 'Doublez vos gains XP', prix: 100, type: 'xp_boost', valeur: 2, duree: 30, categorie: 'boost'),
      ArticleBoutique(id: 5, nom: 'Boost XP x2 (1h)', description: 'Doublez vos gains XP pendant 1h', prix: 180, type: 'xp_boost', valeur: 2, duree: 60, categorie: 'boost'),
      ArticleBoutique(id: 6, nom: 'Pass VIP (7 jours)', description: 'Vies illimitées + Boost XP', prix: 500, type: 'premium', valeur: 1, duree: 10080, categorie: 'premium'),
    ];
  }

  Future<void> _acheterArticle(ArticleBoutique article) async {
    final userState = context.read<UserStateProvider>();
    
    // Vérifier si l'utilisateur a assez de pièces
    if (userState.coins < article.prix) {
      _showMessage('Pas assez de pièces ! Vous avez ${userState.coins} 🪙', isError: true);
      return;
    }

    // Confirmation d'achat
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer l\'achat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(article.icon, size: 48, color: article.iconColor),
            const SizedBox(height: 16),
            Text(article.nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(article.description, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${article.prix} 🪙',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Solde après achat: ${userState.coins - article.prix} 🪙',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B4EAA)),
            child: const Text('Acheter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    setState(() => _isPurchasing = true);

    try {
      final token = widget.token ?? userState.token;
      
      if (token == null) {
        // Achat local sans backend
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
        // Mettre à jour l'état local
        await _applyPurchaseLocally(article, userState);
        _showMessage('${data['message']} - ${data['effet']}');
      } else {
        _showMessage(data['message'] ?? 'Erreur lors de l\'achat', isError: true);
      }
    } catch (e) {
      debugPrint('Erreur achat: $e');
      // En cas d'erreur réseau, appliquer localement
      await _applyPurchaseLocally(article, userState);
    } finally {
      setState(() => _isPurchasing = false);
    }
  }

  Future<void> _applyPurchaseLocally(ArticleBoutique article, UserStateProvider userState) async {
    // Déduire les pièces
    if (!await userState.spendCoins(article.prix)) {
      _showMessage('Pas assez de pièces !', isError: true);
      return;
    }

    // Appliquer l'effet selon le type
    switch (article.type) {
      case 'vie':
        // Ajouter les vies
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
        _showMessage('+${article.valeur} pièces ajoutées !');
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
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserStateProvider>();
    
    // Grouper les articles par catégorie
    final Map<String, List<ArticleBoutique>> articlesByCategory = {};
    for (final article in _articles) {
      articlesByCategory.putIfAbsent(article.categorie, () => []);
      articlesByCategory[article.categorie]!.add(article);
    }

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
                const AppHeader(centerTitle: true),
                
                // Titre et solde
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back, color: Colors.black),
                      ),
                      const Expanded(
                        child: Text(
                          'Boutique',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Afficher le solde
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${userState.coins}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Dépensez vos pièces pour booster votre progression !',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B4EAA)))
                      : _isPurchasing
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: Color(0xFF6B4EAA)),
                                  SizedBox(height: 16),
                                  Text('Achat en cours...'),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadArticles,
                              child: ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                children: articlesByCategory.entries.map((entry) {
                                  return _buildCategorySection(entry.key, entry.value, userState);
                                }).toList(),
                              ),
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

  Widget _buildCategorySection(String category, List<ArticleBoutique> articles, UserStateProvider userState) {
    String categoryTitle;
    switch (category) {
      case 'consommable':
        categoryTitle = '❤️ Vies';
        break;
      case 'boost':
        categoryTitle = '⚡ Boosts';
        break;
      case 'premium':
        categoryTitle = '⭐ Premium';
        break;
      case 'cosmétique':
        categoryTitle = '🎨 Cosmétiques';
        break;
      default:
        categoryTitle = category;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            categoryTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...articles.map((article) => _buildArticleCard(article, userState)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildArticleCard(ArticleBoutique article, UserStateProvider userState) {
    final canAfford = userState.coins >= article.prix;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: canAfford ? () => _acheterArticle(article) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône de l'article
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: article.iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(article.icon, color: article.iconColor, size: 32),
              ),
              const SizedBox(width: 16),
              
              // Nom et description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.nom,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Prix et bouton
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: canAfford ? const Color(0xFF6B4EAA) : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${article.prix}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('🪙', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  if (!canAfford)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Insuffisant',
                        style: TextStyle(color: Colors.red[400], fontSize: 11),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
