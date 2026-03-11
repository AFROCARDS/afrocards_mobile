import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'sponsored_challenge_list_screen.dart';
import 'sponsored_challenge_result_screen.dart';

/// Modèles pour les questions
class Question {
  final int id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final reponses = json['Reponses'] as List? ?? [];
    return Question(
      id: json['idQuestion'] ?? json['id'] ?? 0,
      question: json['contenu'] ?? json['question'] ?? '',
      options: reponses.map((r) => r['texte'].toString()).toList().cast<String>(),
      correctAnswerIndex: (json['bonneReponseIndex'] ?? 0) as int,
    );
  }
}

/// Couleurs du design
class _DesignColors {
  static const Color primary = Color(0xFFFFB74D);
  static const Color secondary = Color(0xFF9C27B0);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color green = Color(0xFF4CAF50);
  static const Color pink = Color(0xFFE91E63);
}

/// Écran de jeu pour le challenge sponsorisé
class SponsoredChallengeGameScreen extends StatefulWidget {
  final SponsoredChallenge challenge;
  final String? token;

  const SponsoredChallengeGameScreen({
    super.key,
    required this.challenge,
    this.token,
  });

  @override
  State<SponsoredChallengeGameScreen> createState() =>
      _SponsoredChallengeGameScreenState();
}

class _SponsoredChallengeGameScreenState
    extends State<SponsoredChallengeGameScreen> {
  late List<Question> _questions;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  int? _selectedAnswerIndex;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      // Pour ce prototype, on génère des questions de test
      // En prod, vous récupéreriez les questions du backend
      _questions = _generateTestQuestions();
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Erreur: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Question> _generateTestQuestions() {
    return [
      Question(
        id: 1,
        question: 'Quel est le capital de la France?',
        options: ['Lyon', 'Paris', 'Marseille', 'Nice'],
        correctAnswerIndex: 1,
      ),
      Question(
        id: 2,
        question: 'En quelle année l\'homme a-t-il marché sur la lune?',
        options: ['1965', '1969', '1971', '1973'],
        correctAnswerIndex: 1,
      ),
      Question(
        id: 3,
        question: 'Quel est le plus grand océan du monde?',
        options: ['Atlantique', 'Indien', 'Pacifique', 'Arctique'],
        correctAnswerIndex: 2,
      ),
      Question(
        id: 4,
        question: 'Combien de continents y a-t-il?',
        options: ['5', '6', '7', '8'],
        correctAnswerIndex: 2,
      ),
      Question(
        id: 5,
        question: 'Quel est le pays le plus peuplé?',
        options: ['Inde', 'Chine', 'États-Unis', 'Indonésie'],
        correctAnswerIndex: 0,
      ),
      Question(
        id: 6,
        question: 'Quel élément a le symbole chimique Au?',
        options: ['Argent', 'Or', 'Aluminium', 'Azote'],
        correctAnswerIndex: 1,
      ),
      Question(
        id: 7,
        question: 'Qui a peint la Joconde?',
        options: ['Van Gogh', 'Léonard de Vinci', 'Michelangelo', 'Raphael'],
        correctAnswerIndex: 1,
      ),
      Question(
        id: 8,
        question: 'Quel est le désert le plus grand du monde?',
        options: ['Kalahari', 'Sahara', 'Gobi', 'Syrien'],
        correctAnswerIndex: 1,
      ),
      Question(
        id: 9,
        question: 'En quelle année l\'Afrique du Sud a-t-elle aboli l\'apartheid?',
        options: ['1990', '1991', '1992', '1994'],
        correctAnswerIndex: 3,
      ),
      Question(
        id: 10,
        question: 'Quel est le plus haut sommet d\'Afrique?',
        options: ['Mont Kenya', 'Kilimandjaro', 'Atlas', 'Ruwenzori'],
        correctAnswerIndex: 1,
      ),
    ];
  }

  void _selectAnswer(int index) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswerIndex = index;
      _isAnswered = true;

      if (index == _questions[_currentQuestionIndex].correctAnswerIndex) {
        _score++;
      }
    });

    // Auto-advance après 1.5 secondes
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        if (_currentQuestionIndex < _questions.length - 1) {
          _nextQuestion();
        } else {
          _finishChallenge();
        }
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestionIndex++;
      _isAnswered = false;
      _selectedAnswerIndex = null;
    });
    _scrollToTop();
  }

  void _scrollToTop() {
    // Auto-scroll au top de la page
  }

  void _finishChallenge() async {
    // Soumettre le résultat au backend
    final userState = context.read<UserStateProvider>();
    final token = widget.token ?? userState.token;

    try {
      // 🔍 DEBUG: Logs soumission
      debugPrint('🚀 === SOUMISSION RÉSULTAT CHALLENGE ===');
      debugPrint('🎯 Challenge ID: ${widget.challenge.idChallenge}');
      debugPrint('📊 Score: $_score / ${_questions.length}');
      debugPrint('📱 Token: ${token ?? "NULL"}');

      final fullUrl = ApiEndpoints.buildUrl(ApiEndpoints.sponsoredChallengeSubmitResult);
      debugPrint('🌐 URL: $fullUrl');

      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'challengeId': widget.challenge.idChallenge,
          'score': _score,
          'totalQuestions': _questions.length,
        }),
      );

      debugPrint('📊 Response Status: ${response.statusCode}');
      debugPrint('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Résultat reçu: ${result['data']}');
        debugPrint('🏆 Trophy? ${result['data']?['trophy']}');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SponsoredChallengeResultScreen(
                challenge: widget.challenge,
                score: _score,
                totalQuestions: _questions.length,
                result: result,
              ),
            ),
          );
        }
      } else {
        debugPrint('❌ ERREUR HTTP ${response.statusCode}');
        debugPrint('📄 Response: ${response.body}');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ === ERREUR SOUMISSION CHALLENGE ===');
      debugPrint('❌ Exception: $e');
      debugPrint('❌ Type: ${e.runtimeType}');
      
      // Continuer même si erreur
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SponsoredChallengeResultScreen(
              challenge: widget.challenge,
              score: _score,
              totalQuestions: _questions.length,
              result: null,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: _DesignColors.primary),
              const SizedBox(height: 20),
              Text(
                'Chargement...',
                style: TextStyle(color: colors.textPrimary),
              ),
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      body: Stack(
        children: [
          // Background
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
                // Header personnalisé
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(Icons.arrow_back,
                              color: colors.textPrimary),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.challenge.titre,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _DesignColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentQuestionIndex + 1}/${_questions.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _DesignColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress bar
                Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: colors.divider,
                      valueColor: const AlwaysStoppedAnimation(
                          _DesignColors.primary),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Question
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colors.cardBackground,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            question.question,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Options
                        Column(
                          children: List.generate(question.options.length, (index) {
                            final isCorrect =
                                index == question.correctAnswerIndex;
                            final isSelected = index == _selectedAnswerIndex;
                            final isAnsweredWrong =
                                _isAnswered && isSelected && !isCorrect;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () => _selectAnswer(index),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _isAnswered
                                        ? (isCorrect && isSelected
                                            ? _DesignColors.green
                                                .withOpacity(0.15)
                                            : (isAnsweredWrong
                                                ? _DesignColors.pink
                                                    .withOpacity(0.15)
                                                : colors.cardBackground))
                                        : (isSelected
                                            ? _DesignColors.primary
                                                .withOpacity(0.15)
                                            : colors.cardBackground),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _isAnswered
                                          ? (isCorrect && isSelected
                                              ? _DesignColors.green
                                              : (isAnsweredWrong
                                                  ? _DesignColors.pink
                                                  : colors.divider))
                                          : (isSelected
                                              ? _DesignColors.primary
                                              : colors.divider),
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Numéro/Icône
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _isAnswered
                                              ? (isCorrect && isSelected
                                                  ? _DesignColors.green
                                                  : (isAnsweredWrong
                                                      ? _DesignColors.pink
                                                      : colors.divider))
                                              : (isSelected
                                                  ? _DesignColors.primary
                                                  : colors.divider),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: _isAnswered
                                              ? Icon(
                                                  isCorrect && isSelected
                                                      ? Icons.check
                                                      : (isAnsweredWrong
                                                          ? Icons.close
                                                          : null),
                                                  color: Colors.white,
                                                )
                                              : Text(
                                                  String.fromCharCode(65 + index),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // Texte
                                      Expanded(
                                        child: Text(
                                          question.options[index],
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }
}
