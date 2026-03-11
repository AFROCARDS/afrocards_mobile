import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../data/models/notification_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Couleurs du design
class _DesignColors {
  static const Color primary = Color(0xFFFFB74D);
  static const Color secondary = Color(0xFF9C27B0);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color pink = Color(0xFFE91E63);
  static const Color green = Color(0xFF4CAF50);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color unreadBg = Color(0xFFF7F3FF);
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _loading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loading = true);
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.notifications)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> notifList = data['data'] ?? [];
        setState(() {
          _notifications = notifList
              .map((json) => NotificationModel.fromJson(json))
              .toList();
          _unreadCount = _notifications.where((n) => !n.estLue).length;
        });
      }
    } catch (e) {
      debugPrint('Erreur fetch notifications: $e');
    }

    setState(() => _loading = false);
  }

  Future<void> _markAsRead(int idNotif) async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.markNotificationAsRead(idNotif))),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.idNotif == idNotif);
          if (index != -1) {
            _notifications[index] = _notifications[index].copyWith(estLue: true);
            _unreadCount = _notifications.where((n) => !n.estLue).length;
          }
        });
      }
    } catch (e) {
      debugPrint('Erreur marquer comme lu: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.markAllAsRead)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _notifications = _notifications.map((n) => n.copyWith(estLue: true)).toList();
          _unreadCount = 0;
        });
        _showSnackBar('Toutes les notifications marquées comme lues');
      }
    } catch (e) {
      debugPrint('Erreur marquer tout comme lu: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        backgroundColor: _DesignColors.secondary,
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'ami':
        return Icons.person_add;
      case 'badge':
        return Icons.emoji_events;
      case 'message':
        return Icons.message;
      case 'challenge':
        return Icons.sports_esports;
      case 'promo':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'ami':
        return _DesignColors.cyan;
      case 'badge':
        return _DesignColors.primary;
      case 'message':
        return _DesignColors.green;
      case 'challenge':
        return _DesignColors.pink;
      case 'promo':
        return _DesignColors.secondary;
      default:
        return _DesignColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    } else if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
                const AppHeader(
                  title: 'Notifications',
                  centerTitle: true,
                ),
                // Badge compte non lues + bouton tout lire
                if (_unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _DesignColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _DesignColors.secondary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _DesignColors.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'notification${_unreadCount > 1 ? 's' : ''} non lue${_unreadCount > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: _DesignColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _markAllAsRead,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Tout lire',
                            style: TextStyle(
                              color: _DesignColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: _DesignColors.primary),
                        )
                      : _notifications.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _fetchNotifications,
                              color: _DesignColors.secondary,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _notifications.length,
                                itemBuilder: (context, idx) => _buildNotificationCard(_notifications[idx]),
                              ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _DesignColors.textSecondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: _DesignColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _DesignColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vos notifications apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: _DesignColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    final iconColor = _getNotificationColor(notif.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notif.estLue ? Colors.white : _DesignColors.unreadBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!notif.estLue) {
              _markAsRead(notif.idNotif);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône type
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notif.type),
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.titre,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: notif.estLue ? FontWeight.w500 : FontWeight.bold,
                                color: _DesignColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!notif.estLue)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: _DesignColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.contenu,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _DesignColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(notif.dateCreation),
                        style: TextStyle(
                          fontSize: 12,
                          color: _DesignColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
