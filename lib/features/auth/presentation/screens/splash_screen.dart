import 'package:flutter/material.dart';
import 'dart:async';

import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
    _navigateToOnboarding();
  }

  void _navigateToOnboarding() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // TODO: Décommenter quand OnboardingScreen sera importé
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OnboardingScreen(),
          ),
        );

        debugPrint('✅ Navigation vers l\'écran d\'onboarding');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. L'image de fond (Background)
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/img.png', // Ton image de motifs blancs
              fit: BoxFit.cover,
            ),
          ),

          // 2. Le Logo au milieu
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _fadeAnimation,
                child: Image.asset(
                  'assets/images/logos/logo_afc.png', // Ton logo AfroCards
                  width: MediaQuery.of(context).size.width * 0.7,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // 3. Optionnel : Un indicateur de chargement discret en bas
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}