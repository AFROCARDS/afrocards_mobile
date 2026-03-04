import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _coins = 0;
  int _lives = 0;
  int _maxLives = 10;
  bool _loading = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchWallet();
    _fetchTransactions();
  }

  Future<void> _fetchWallet() async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.portefeuille)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _coins = data['data']['coins'] ?? 0;
          _lives = data['data']['vies'] ?? 0;
          _maxLives = data['data']['maxVies'] ?? 10;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchTransactions() async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.transactionHistory)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _transactions = data['data'] ?? [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
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
                  title: 'Mon Portefeuille',
                  onBackTap: () => Navigator.of(context).pop(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF9C4), Color(0xFFFFECB3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/icons/wallet.png', width: 40, height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, size: 40)),
                            const SizedBox(width: 12),
                            Text('$_coins', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Coins', style: TextStyle(fontSize: 16, color: Colors.black54)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF9C27B0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text('+ Acheter'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Historique des Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildTransactionList(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('Aucune transaction'));
    }
    // Regrouper par date
    Map<String, List<dynamic>> grouped = {};
    for (var item in _transactions) {
      final date = DateTime.tryParse(item['dateTransaction'] ?? '') ?? DateTime.now();
      final key = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      grouped.putIfAbsent(key, () => []).add(item);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      itemCount: sortedKeys.length,
      itemBuilder: (context, idx) {
        final date = sortedKeys[idx];
        final items = grouped[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(date, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
            ),
            ...items.map((item) => _TransactionCard(data: item)).toList(),
          ],
        );
      },
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TransactionCard({required this.data});
  @override
  Widget build(BuildContext context) {
    final type = data['type'] ?? '';
    final montant = data['montant'] ?? 0;
    final description = data['description'] ?? '';
    final xp = data['xp'] ?? 0;
    final coins = data['coins'] ?? 0;
    final isGain = montant > 0;
    return ListTile(
      leading: Icon(isGain ? Icons.add_circle : Icons.remove_circle, color: isGain ? Colors.green : Colors.red, size: 32),
      title: Text(description, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (xp != 0) Text('${isGain ? '+' : ''}$xp XP', style: const TextStyle(color: Color(0xFF9C27B0), fontWeight: FontWeight.bold)),
          if (coins != 0) Text('${isGain ? '+' : ''}$coins Coins', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        ],
      ),
      trailing: Text('${isGain ? '+' : ''}$montant Coins', style: TextStyle(color: isGain ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
