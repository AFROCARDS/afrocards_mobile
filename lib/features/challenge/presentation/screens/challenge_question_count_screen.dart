import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'challenge_matching_screen.dart';

/// Écran de sélection du nombre de questions pour le mode Challenge
/// Conforme à la maquette: 10, 15, 20 questions avec bouton Valider
class ChallengeQuestionCountScreen extends StatefulWidget {
  final String? token;

  const ChallengeQuestionCountScreen({
    super.key,
    this.token,
  });

  @override
  State<ChallengeQuestionCountScreen> createState() =>
      _ChallengeQuestionCountScreenState();
}

class _ChallengeQuestionCountScreenState
    extends State<ChallengeQuestionCountScreen> {
  int _selectedCount = 10;

  final List<int> _questionCounts = [10, 15, 20];

  void _onValidate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeMatchingScreen(
          questionCount: _selectedCount,
          token: widget.token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                AppHeader(
                  title: 'Mode Challenge',
                  onBackTap: () => Navigator.of(context).pop(), centerTitle: true,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Titre
                        const Text(
                          'Definissez le nombre de questions\nqui vous convient',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Options de nombre de questions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _questionCounts.map((count) {
                            final isSelected = _selectedCount == count;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedCount = count),
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFF5F0FF)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF6B4EAA)
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                      BoxShadow(
                                        color: const Color(0xFF6B4EAA)
                                            .withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? const Color(0xFF6B4EAA)
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 40),

                        // Bouton Valider
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: _onValidate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8E4A8),
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Valider',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Lien retour menu principal
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Retour au menu principal',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(
        currentIndex: 0,
      ),
    );
  }
}