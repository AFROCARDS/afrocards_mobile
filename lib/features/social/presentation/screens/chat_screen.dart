import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'report_player_dialog.dart';

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
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
        // Scroll to bottom after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
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

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text('Voir le profil'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to friend profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: const Text('Bloquer'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Block user
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Signaler'),
              onTap: () {
                Navigator.pop(context);
                showReportPlayerDialog(
                  context: context,
                  playerId: widget.friendId,
                  playerName: widget.friendName,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? dateString) {
    if (dateString == null || dateString.length < 16) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateString.length >= 16 ? dateString.substring(11, 16) : '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserStateProvider>();
    
    return Scaffold(
      body: Stack(
        children: [
          // Background
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
                // App Header
                AppHeader(
                  title: widget.friendName,
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.more_horiz, color: Colors.black87),
                      onPressed: _showOptionsMenu,
                    ),
                  ],
                ),
                
                // Messages List
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _messages.isEmpty
                          ? const Center(
                              child: Text(
                                'Commencez la conversation !',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: _messages.length,
                              itemBuilder: (context, idx) {
                                final msg = _messages[idx];
                                final isMe = msg['isMe'] ?? (msg['idExpediteur'] == userState.joueurId);
                                return _buildMessageBubble(msg, isMe);
                              },
                            ),
                ),
                
                // Input Field
                _buildInputField(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final time = _formatTime(msg['dateEnvoi']?.toString());
    final content = msg['contenu'] ?? '';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Time on left for received messages
          if (!isMe) ...[
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Avatar for received messages
          if (!isMe) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: widget.friendAvatar != null && widget.friendAvatar!.isNotEmpty
                  ? NetworkImage(widget.friendAvatar!)
                  : null,
              child: widget.friendAvatar == null || widget.friendAvatar!.isEmpty
                  ? const Icon(Icons.person, size: 20, color: Colors.white)
                  : null,
            ),
          ],
          
          // Message bubble
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: isMe ? 50 : 8,
                right: isMe ? 0 : 50,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isMe 
                      ? const Color(0xFFE8D44D) // Yellow/gold for sent
                      : const Color(0xFFFF7043), // Orange/coral for received
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          
          // Time on right for sent messages
          if (isMe) ...[
            const SizedBox(width: 8),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Text field with emoji icon
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFFE8D44D),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Emoji button
                  IconButton(
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: () {
                      // TODO: Show emoji picker
                    },
                  ),
                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Ecrire un message...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 10),
          
          // Send button
          GestureDetector(
            onTap: _sending ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB74D).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _sending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
