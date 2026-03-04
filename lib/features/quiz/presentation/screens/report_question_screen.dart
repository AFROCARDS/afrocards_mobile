import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportQuestionScreen extends StatefulWidget {
  final int questionId;
  final String questionText;
  const ReportQuestionScreen({Key? key, required this.questionId, required this.questionText}) : super(key: key);

  @override
  State<ReportQuestionScreen> createState() => _ReportQuestionScreenState();
}

class _ReportQuestionScreenState extends State<ReportQuestionScreen> {
  int? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _submitting = false;
  String? _error;
  String? _success;

  final List<String> _reasons = [
    'Erreur sur la réponse',
    'Explication incorrecte',
    'Réponses à mettre à jour',
    'Autre',
  ];

  Future<void> _submitReport() async {
    setState(() { _submitting = true; _error = null; _success = null; });
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) {
      setState(() { _error = 'Non authentifié.'; _submitting = false; });
      return;
    }
    if (_selectedReason == null) {
      setState(() { _error = 'Veuillez sélectionner un motif.'; _submitting = false; });
      return;
    }
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.buildUrl('/social/report-question')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'idQuestion': widget.questionId,
          'motif': _reasons[_selectedReason!],
          'details': _detailsController.text.trim(),
        }),
      );
      if (response.statusCode == 201) {
        setState(() { _success = 'Signalement envoyé.'; });
        Future.delayed(const Duration(seconds: 2), () => Navigator.of(context).pop());
      } else {
        final data = jsonDecode(response.body);
        setState(() { _error = data['message'] ?? 'Erreur lors de l\'envoi.'; });
      }
    } catch (e) {
      setState(() { _error = 'Erreur réseau.'; });
    }
    setState(() { _submitting = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('SIGNALER UNE QUESTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(widget.questionText, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 18),
              const Center(child: Text('Quel Est Le Problème ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
              const SizedBox(height: 10),
              ...List.generate(_reasons.length, (i) => GestureDetector(
                onTap: () => setState(() => _selectedReason = i),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  margin: const EdgeInsets.only(bottom: 2),
                  color: _selectedReason == i ? const Color(0xFFD1A6F7) : const Color(0xFFF9F6FF),
                  child: Center(
                    child: Text(_reasons[i], style: TextStyle(fontSize: 16, color: _selectedReason == i ? Colors.black : Colors.black87)),
                  ),
                ),
              )),
              const SizedBox(height: 18),
              const Text('Détails (Optionnel)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _detailsController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Fournissez plus de détails...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF9F6FF),
                ),
              ),
              const SizedBox(height: 18),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
              ],
              if (_success != null) ...[
                Text(_success!, style: const TextStyle(color: Colors.green)),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD1A6F7),
                        side: const BorderSide(color: Color(0xFFD1A6F7)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Non, ça va'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4B4B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Soumettre Signalement'),
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
