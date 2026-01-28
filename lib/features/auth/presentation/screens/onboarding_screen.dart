import 'package:flutter/material.dart';

import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  // Liste des images de fond correspondant à chaque étape
  final List<String> _backgroundImages = [
    'assets/images/backgrounds/img_1.png',
    'assets/images/backgrounds/img_2.png',
    'assets/images/backgrounds/img_3.png',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background dynamique qui change selon _currentPage
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Container(
              key: ValueKey<int>(_currentPage),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_backgroundImages[_currentPage]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // 2. Contenu de l'Onboarding
          SafeArea(
            child: Column(
              children: [
                _buildSkipButton(),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _buildOnboardingContent(
                        title: 'Bienvenue sur AfroCards',
                        description: 'Découvrez la culture africaine à travers des quiz passionnants.',
                      ),
                      _buildOnboardingContent(
                        title: 'Apprenez en vous amusant',
                        description: 'Des questions variées sur l\'histoire, la géographie et la culture.',
                      ),
                      _buildOnboardingContent(
                        title: 'Défiez vos amis',
                        description: 'Comparez vos scores et devenez le champion de la culture.',
                      ),
                    ],
                  ),
                ),

                // Section Bas : Indicateurs + Bouton Suivant (comme sur la maquette)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNextButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton() {
    return Align(
      alignment: Alignment.topRight,
      child: TextButton(
        onPressed: _navigateToLogin,
        child: const Text(
          'Passer',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildOnboardingContent({required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Espace pour l'illustration circulaire de ta maquette
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 60),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }



  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: _nextPage,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(_currentPage == _totalPages - 1 ? 'Commencer' : 'Suivant'),
    );
  }
}

// Écran temporaire pour le test
class TemporaryLoginScreen extends StatelessWidget {
  const TemporaryLoginScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Login Screen")));
}