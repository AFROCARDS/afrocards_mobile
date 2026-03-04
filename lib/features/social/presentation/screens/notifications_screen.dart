import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loading = true);
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
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
        setState(() {
          _notifications = data['data'] ?? [];
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
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
                const AppHeader(title: 'Notifications'),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _notifications.isEmpty
                          ? const Center(child: Text('Aucune notification'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                              itemCount: _notifications.length,
                              itemBuilder: (context, idx) {
                                final notif = _notifications[idx];
                                final isUnread = notif['lue'] == false || notif['lue'] == 0;
                                return Container(
                                  color: isUnread ? const Color(0xFFF7F3FF) : Colors.transparent,
                                  child: ListTile(
                                    leading: isUnread
                                        ? const Icon(Icons.circle, color: Color(0xFF9C27B0), size: 12)
                                        : const SizedBox(width: 12),
                                    title: Text(
                                      notif['contenu'] ?? notif['message'] ?? '',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    subtitle: notif['dateCreation'] != null
                                        ? Text(
                                            notif['dateCreation'].toString().substring(0, 16).replaceAll('T', ' '),
                                            style: const TextStyle(fontSize: 12, color: Colors.black38),
                                          )
                                        : null,
                                    onTap: () {
                                      // TODO: Marquer comme lu si besoin
                                    },
                                  ),
                                );
                              },
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
}
