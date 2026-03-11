import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Couleurs du design (identiques à profile_screen)
class _DesignColors {
  static const Color primary = Color(0xFFFFB74D);
  static const Color secondary = Color(0xFF9C27B0);
  static const Color pink = Color(0xFFE91E63);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textMuted = Color(0xFF636E72);
}

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: context.colors.cardBackground,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _DesignColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.help_outline_rounded, color: _DesignColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Signaler une question',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _DesignColors.textDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _DesignColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    questionText,
                    style: const TextStyle(fontSize: 13, color: _DesignColors.secondary, fontWeight: FontWeight.w500),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Quel est le problème ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _DesignColors.textDark)),
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
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: selectedReason == i ? _DesignColors.primary.withOpacity(0.15) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedReason == i ? _DesignColors.primary : Colors.grey.shade200,
                          width: selectedReason == i ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selectedReason == i ? _DesignColors.primary : Colors.transparent,
                              border: Border.all(color: selectedReason == i ? _DesignColors.primary : Colors.grey.shade400, width: 2),
                            ),
                            child: selectedReason == i ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              reasons[i],
                              style: TextStyle(fontSize: 14, fontWeight: selectedReason == i ? FontWeight.w600 : FontWeight.normal, color: _DesignColors.textDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Détails (Optionnel)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _DesignColors.textDark)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: detailsController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Fournissez plus de détails...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _DesignColors.primary, width: 2)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _DesignColors.pink.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: _DesignColors.pink, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(error!, style: const TextStyle(color: _DesignColors.pink, fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                  if (success != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(success!, style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: submitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _DesignColors.textMuted,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Non, ça va', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: submitting ? null : () async {
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
                            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                            body: jsonEncode({'idQuestion': questionId, 'motif': reasons[selectedReason!], 'details': detailsController.text.trim()}),
                          );
                          if (response.statusCode == 201) {
                            setState(() { success = 'Signalement envoyé avec succès.'; });
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
                        backgroundColor: _DesignColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Soumettre', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}
