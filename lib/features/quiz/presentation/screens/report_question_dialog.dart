import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> showReportQuestionDialog({
  required BuildContext context,
  required int questionId,
  required String questionText,
}) async {
  int? selectedReason;
  final detailsController = TextEditingController();
  bool submitting = false;
  String? error;
  String? success;
  final List<String> reasons = [
    'Erreur sur la réponse',
    'Explication incorrecte',
    'Réponses à mettre à jour',
    'Autre',
  ];

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SIGNALER UNE QUESTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(questionText, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 10),
                const Text('Quel Est Le Problème ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(reasons.length, (i) => GestureDetector(
                    onTap: () => setState(() => selectedReason = i),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      margin: const EdgeInsets.only(bottom: 2),
                      color: selectedReason == i ? const Color(0xFFD1A6F7) : const Color(0xFFF9F6FF),
                      child: Center(
                        child: Text(reasons[i], style: TextStyle(fontSize: 15, color: selectedReason == i ? Colors.black : Colors.black87)),
                      ),
                    ),
                  )),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Détails (Optionnel)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: detailsController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Fournissez plus de détails...',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFF9F6FF),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                  if (success != null) ...[
                    const SizedBox(height: 8),
                    Text(success!, style: const TextStyle(color: Colors.green)),
                  ],
                ],
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: submitting ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD1A6F7),
                  side: const BorderSide(color: Color(0xFFD1A6F7)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                ),
                child: const Text('Non, ça va'),
              ),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        if (selectedReason == null) {
                          setState(() => error = 'Veuillez sélectionner un motif.');
                          return;
                        }
                        setState(() { submitting = true; error = null; success = null; });
                        final userState = context.read<UserStateProvider>();
                        final token = userState.token;
                        if (token == null) {
                          setState(() { error = 'Non authentifié.'; submitting = false; });
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
                              'idQuestion': questionId,
                              'motif': reasons[selectedReason!],
                              'details': detailsController.text.trim(),
                            }),
                          );
                          if (response.statusCode == 201) {
                            setState(() { success = 'Signalement envoyé.'; });
                            await Future.delayed(const Duration(seconds: 1));
                            Navigator.of(context).pop();
                          } else {
                            final data = jsonDecode(response.body);
                            setState(() { error = data['message'] ?? 'Erreur lors de l\'envoi.'; });
                          }
                        } catch (e) {
                          setState(() { error = 'Erreur réseau.'; });
                        }
                        setState(() { submitting = false; });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4B4B),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                ),
                child: submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Soumettre Signalement'),
              ),
            ],
          );
        },
      );
    },
  );
}
