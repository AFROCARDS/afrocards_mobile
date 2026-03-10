import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../shared/widgets/app_header.dart';

/// Couleurs du design (identiques à profile_screen)
class _DesignColors {
  static const Color primary = Color(0xFFFFB74D);
  static const Color secondary = Color(0xFF9C27B0);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color pink = Color(0xFFE91E63);
  static const Color green = Color(0xFF4CAF50);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);
}

/// Écran pour voir le profil public d'un joueur
class PlayerProfileScreen extends StatefulWidget {
  final int idJoueur;
  final String? pseudo;

  const PlayerProfileScreen({
    Key? key,
    required this.idJoueur,
    this.pseudo,
  }) : super(key: key);

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  Map<String, dynamic>? _profilData;
  bool _loading = true;
  String? _error;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfil();
  }

  Future<void> _fetchProfil() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) {
      setState(() {
        _error = 'Non authentifié';
        _loading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.profilJoueur(widget.idJoueur))),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _profilData = data['data'];
            _loading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Erreur inconnue';
            _loading = false;
          });
        }
      } else if (response.statusCode == 403) {
        setState(() {
          _error = 'Ce profil n\'est pas accessible';
          _loading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _error = 'Joueur introuvable';
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur de chargement';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur réseau';
        _loading = false;
      });
    }
  }

  Future<void> _envoyerDemandeAmi() async {
    setState(() => _actionLoading = true);

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
        body: jsonEncode({'idJoueur': widget.idJoueur}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _showSnackBar('Demande d\'ami envoyée !', isSuccess: true);
        _fetchProfil(); // Rafraîchir pour mettre à jour le statut
      } else {
        _showSnackBar(data['message'] ?? 'Erreur', isSuccess: false);
      }
    } catch (e) {
      _showSnackBar('Erreur réseau', isSuccess: false);
    }

    setState(() => _actionLoading = false);
  }

  Future<void> _accepterDemande(int idAmitie) async {
    setState(() => _actionLoading = true);

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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _showSnackBar('Demande acceptée !', isSuccess: true);
        _fetchProfil();
      } else {
        _showSnackBar(data['message'] ?? 'Erreur', isSuccess: false);
      }
    } catch (e) {
      _showSnackBar('Erreur réseau', isSuccess: false);
    }

    setState(() => _actionLoading = false);
  }

  Future<void> _supprimerAmi(int idAmitie) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _DesignColors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_remove, color: _DesignColors.pink),
            ),
            const SizedBox(width: 12),
            const Text('Retirer l\'ami'),
          ],
        ),
        content: const Text('Êtes-vous sûr de vouloir retirer cet ami ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: _DesignColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _actionLoading = true);

    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.amisSupprimer(idAmitie))),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _showSnackBar('Ami retiré', isSuccess: true);
        _fetchProfil();
      } else {
        _showSnackBar(data['message'] ?? 'Erreur', isSuccess: false);
      }
    } catch (e) {
      _showSnackBar('Erreur réseau', isSuccess: false);
    }

    setState(() => _actionLoading = false);
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? _DesignColors.green : _DesignColors.pink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _getBadgeColor(String? couleur) {
    if (couleur == null) return _DesignColors.textMuted;
    // Convertir la couleur hex en Color
    try {
      final hex = couleur.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return _DesignColors.textMuted;
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
                AppHeader(
                  onBackTap: () => Navigator.pop(context),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: _DesignColors.primary))
                      : _error != null
                          ? _buildErrorState()
                          : _buildProfileContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _DesignColors.pink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 48, color: _DesignColors.pink),
            ),
            const SizedBox(height: 20),
            Text(
              _error ?? 'Erreur',
              style: const TextStyle(fontSize: 16, color: _DesignColors.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchProfil,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _DesignColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    final profil = _profilData!;
    final pseudo = profil['pseudo'] ?? 'Joueur';
    final avatarURL = profil['avatarURL'];
    final bio = profil['bio'] as String?;
    final nationalite = profil['nationalite'] as String?;
    final totalXP = profil['totalXP'] ?? profil['pointsXP'] ?? 0;
    final badge = profil['badge'] as Map<String, dynamic>?;
    final nombreAmis = profil['nombreAmis'] ?? 0;
    final nombreTrophees = profil['nombreTrophees'] ?? 0;
    final trophees = profil['trophees'] as List<dynamic>? ?? [];
    final statutAmitie = profil['statutAmitie'] ?? 'none';
    final idAmitie = profil['idAmitie'];
    final estMoi = profil['estMoi'] == true;

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
            child: Column(
              children: [
                // Avatar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _getBadgeColor(badge?['couleur']).withOpacity(0.5),
                        _getBadgeColor(badge?['couleur']),
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
                      backgroundImage: avatarURL != null && avatarURL.isNotEmpty
                          ? NetworkImage(avatarURL)
                          : null,
                      child: avatarURL == null || avatarURL.isEmpty
                          ? Icon(Icons.person, color: Colors.grey.shade400, size: 50)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pseudo
                Text(
                  pseudo,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _DesignColors.textDark,
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
                      color: _DesignColors.textMuted,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Badge
                if (badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getBadgeColor(badge['couleur']).withOpacity(0.2),
                          _getBadgeColor(badge['couleur']).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getBadgeColor(badge['couleur']).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars, size: 16, color: _getBadgeColor(badge['couleur'])),
                        const SizedBox(width: 6),
                        Text(
                          badge['nom'] ?? 'Novice',
                          style: TextStyle(
                            color: _getBadgeColor(badge['couleur']),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Bouton action (ajouter ami, en attente, retirer)
                if (!estMoi) _buildActionButton(statutAmitie, idAmitie),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(child: _buildStatCard('XP', totalXP.toString(), Icons.bolt, _DesignColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Trophées', nombreTrophees.toString(), Icons.emoji_events, _DesignColors.secondary)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Amis', nombreAmis.toString(), Icons.people, _DesignColors.cyan)),
            ],
          ),

          // Trophées Section
          if (trophees.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildTropheesSection(trophees),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildActionButton(String statut, int? idAmitie) {
    if (_actionLoading) {
      return const SizedBox(
        width: double.infinity,
        child: Center(
          child: CircularProgressIndicator(color: _DesignColors.primary),
        ),
      );
    }

    switch (statut) {
      case 'ami':
        return SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: idAmitie != null ? () => _supprimerAmi(idAmitie) : null,
                  icon: const Icon(Icons.person_remove),
                  label: const Text('Retirer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _DesignColors.pink,
                    side: const BorderSide(color: _DesignColors.pink),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Naviguer vers la messagerie ou défier
                    _showSnackBar('Fonctionnalité à venir !', isSuccess: true);
                  },
                  icon: const Icon(Icons.sports_esports),
                  label: const Text('Défier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _DesignColors.secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'demande_envoyee':
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.hourglass_top),
            label: const Text('Demande envoyée'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _DesignColors.textMuted,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );

      case 'demande_recue':
        return SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Refuser la demande
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Refuser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _DesignColors.textMuted,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: idAmitie != null ? () => _accepterDemande(idAmitie) : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Accepter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _DesignColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );

      default: // 'none'
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _envoyerDemandeAmi,
            icon: const Icon(Icons.person_add),
            label: const Text('Ajouter en ami'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DesignColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
    }
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _DesignColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: _DesignColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTropheesSection(List<dynamic> trophees) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _DesignColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events, color: _DesignColors.secondary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Trophées (${trophees.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _DesignColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: trophees.take(6).map((trophee) => _buildTropheeChip(trophee)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTropheeChip(dynamic trophee) {
    final nom = trophee['nom'] ?? 'Trophée';
    final rarete = (trophee['rarete'] ?? '').toString().toLowerCase();

    Color rareteColor;
    switch (rarete) {
      case 'legendaire':
        rareteColor = const Color(0xFFFFD700);
        break;
      case 'epique':
        rareteColor = _DesignColors.secondary;
        break;
      case 'rare':
        rareteColor = _DesignColors.cyan;
        break;
      default:
        rareteColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: rareteColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: rareteColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.military_tech, color: rareteColor, size: 16),
          const SizedBox(width: 6),
          Text(
            nom,
            style: TextStyle(
              color: rareteColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
