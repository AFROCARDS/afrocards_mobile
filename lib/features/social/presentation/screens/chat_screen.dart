import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'report_player_screen.dart';

class ChatScreen extends StatefulWidget {
  final int friendId;
  final String friendName;
  final String? friendAvatar;
  const ChatScreen({Key? key, required this.friendId, required this.friendName, this.friendAvatar}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> _messages = [];
  bool _loading = true;
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() => _loading = true);
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl('/social/messages/${widget.friendId}')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages = data['data'] ?? [];
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.buildUrl('/social/messages')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'idDestinataire': widget.friendId,
          'contenu': text,
        }),
      );
      if (response.statusCode == 201) {
        _controller.clear();
        _fetchMessages();
      }
    } catch (_) {}
    setState(() => _sending = false);
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
                Row(
                  children: [
                    Expanded(
                      child: AppHeader(
                        title: widget.friendName,
                        centerTitle: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.report_gmailerrorred_rounded, color: Color(0xFFFF4B4B)),
                      tooltip: 'Signaler',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ReportPlayerScreen(
                              playerId: widget.friendId,
                              playerName: widget.friendName,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          reverse: false,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          itemCount: _messages.length,
                          itemBuilder: (context, idx) {
                            final msg = _messages[idx];
                            final isMe = msg['isMe'] ?? (msg['idExpediteur'] == userState.joueurId);
                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.white : const Color(0xFFF3EFFF),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isMe ? const Color(0xFFE8D44D) : const Color(0xFF9C27B0),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(msg['contenu'] ?? '', style: const TextStyle(fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(
                                      msg['dateEnvoi'] != null ? msg['dateEnvoi'].toString().substring(11, 16) : '',
                                      style: const TextStyle(fontSize: 12, color: Colors.black38),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Ecrire un message...',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sending ? null : _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB74D),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
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
}
