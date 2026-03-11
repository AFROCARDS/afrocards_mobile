import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import 'sponsored_challenge_list_screen.dart';
import 'sponsored_challenge_result_screen.dart';

/// Modèle pour une question
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
    extends State<SponsoredChallengeGameScreen> with TickerProviderStateMixin {
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  String? _error;

  // Réponse sélectionnée
  int? _selectedAnswerIndex;
  bool _hasAnswered = false;
  bool? _isCorrect;

  // Timer
  late int _timeRemaining;
  Timer? _timer;
  late AnimationController _timerAnimationController;

  @override
  void initState() {
    super.initState();
    _timerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      debugPrint('🚀 === CHARGEMENT QUESTIONS CHALLENGE ===');
      debugPrint('🎯 Challenge ID: ${widget.challenge.idChallenge}');

      _questions = _generateTestQuestions();
      setState(() => _isLoading = false);

      if (_questions.isNotEmpty) {
        _startTimer();
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement questions: $e');
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
        correctAnswerIndex: 1,
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

  void _startTimer() {
    _timeRemaining = 30;

    _timerAnimationController.duration = Duration(seconds: _timeRemaining);
    _timerAnimationController.reset();
    _timerAnimationController.forward();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0 && !_hasAnswered) {
        setState(() {
          _timeRemaining--;
        });
      } else if (_timeRemaining == 0 && !_hasAnswered) {
        _onTimeUp();
      }
    });
  }

  void _onTimeUp() {
    _timer?.cancel();
    setState(() {
      _hasAnswered = true;
      _isCorrect = false;
    });
  }

  void _selectAnswer(int index) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswerIndex = index;
    });
  }

  void _confirmAnswer() {
    if (_selectedAnswerIndex == null || _hasAnswered) return;

    _timer?.cancel();
    _timerAnimationController.stop();

    final question = _questions[_currentQuestionIndex];
    final isCorrect = _selectedAnswerIndex == question.correctAnswerIndex;

    setState(() {
      _hasAnswered = true;
      _isCorrect = isCorrect;
      if (isCorrect) {
        _score++;
      }
    });

    debugPrint(
        '💡 Réponse: ${question.options[_selectedAnswerIndex!]} - ${isCorrect ? '✅ Correct' : '❌ Incorrect'}');
  }

  void _skipQuestion() {
    _timer?.cancel();
    _nextQuestion();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _hasAnswered = false;
        _isCorrect = null;
      });
      _startTimer();
    } else {
      _finishChallenge();
    }
  }

  void _finishChallenge() async {
    final userState = context.read<UserStateProvider>();
    final token = widget.token ?? userState.token;

    try {
      debugPrint('🚀 === SOUMISSION RÉSULTAT CHALLENGE ===');
      debugPrint('🎯 Challenge ID: ${widget.challenge.idChallenge}');
      debugPrint('📊 Score: $_score / ${_questions.length}');
      debugPrint('📱 Token: ${token ?? "NULL"}');

      final fullUrl =
          ApiEndpoints.buildUrl(ApiEndpoints.sponsoredChallengeSubmitResult);
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

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text('Aucune question disponible',
              style: TextStyle(color: colors.textPrimary)),
        ),
      );
    }

    return _buildQuizScreen();
  }

  Widget _buildQuizScreen() {
    final currentQuestion = _questions[_currentQuestionIndex];
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
                const AppHeader(centerTitle: true),

                _buildQuestionHeader(currentQuestion),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildQuestionText(currentQuestion),
                        const SizedBox(height: 24),
                        _buildAnswerOptions(currentQuestion),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(Question question) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back, color: context.colors.textPrimary),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_score/${_questions.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.star, color: Colors.amber.shade700, size: 16),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (!_hasAnswered) _buildTimerBar(),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    final progress = _timeRemaining / 30;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.grey.shade200,
      ),
      child: Stack(
        children: [
          ScaleTransition(
            alignment: Alignment.centerLeft,
            scale: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _timerAnimationController,
                curve: Curves.linear,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: progress > 0.3 ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),

          Center(
            child: Text(
              '$_timeRemaining"',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionText(Question question) {
    return Column(
      children: [
        Text(
          question.question,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.colors.textPrimary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerOptions(Question question) {
    return Column(
      children: question.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = _selectedAnswerIndex == index;
        final isCorrectAnswer = index == question.correctAnswerIndex;

        Color backgroundColor = Colors.white;
        Color borderColor = Colors.grey.shade200;
        Color textColor = Colors.black87;

        if (_hasAnswered) {
          if (isCorrectAnswer) {
            backgroundColor = Colors.green.shade50;
            borderColor = Colors.green;
            textColor = Colors.green.shade700;
          } else if (isSelected && !isCorrectAnswer) {
            backgroundColor = Colors.red.shade50;
            borderColor = Colors.red;
            textColor = Colors.red.shade700;
          }
        } else if (isSelected) {
          backgroundColor = _DesignColors.primary.withOpacity(0.1);
          borderColor = _DesignColors.primary;
          textColor = _DesignColors.primary;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: _hasAnswered ? null : () => _selectAnswer(index),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor,
                        fontWeight: isSelected || (_hasAnswered && isCorrectAnswer)
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (_hasAnswered && isCorrectAnswer)
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                  if (_hasAnswered && isSelected && !isCorrectAnswer)
                    Icon(Icons.cancel, color: Colors.red, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _hasAnswered ? null : _skipQuestion,
              child: Text(
                'Passer',
                style: TextStyle(
                  fontSize: 16,
                  color: _hasAnswered ? Colors.grey : Colors.black54,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _hasAnswered
                  ? _nextQuestion
                  : (_selectedAnswerIndex != null ? _confirmAnswer : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: _DesignColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Text(
                _hasAnswered ? 'Continuer' : 'Confirmer',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
