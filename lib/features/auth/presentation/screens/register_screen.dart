import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  // Contrôleurs
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int _age = 19;
  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Étape 1 : Valider le nom
      if (_nameController.text.trim().isEmpty) {
        _showError("Veuillez entrer votre nom");
        return;
      }
      if (_nameController.text.trim().length < 2) {
        _showError("Le nom doit contenir au moins 2 caractères");
        return;
      }

      setState(() => _currentStep = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Étape 2 : Valider email et mot de passe puis enregistrer
      _handleRegister();
    }
  }

  Future<void> _handleRegister() async {
    // Validation des champs
    if (_emailController.text.trim().isEmpty) {
      _showError("Veuillez entrer votre email");
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showError("Email invalide");
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showError("Veuillez entrer un mot de passe");
      return;
    }

    if (_passwordController.text.length < 8) {
      _showError("Le mot de passe doit contenir au moins 8 caractères");
      return;
    }

    if (!_hasUpperCase(_passwordController.text) || !_hasDigit(_passwordController.text)) {
      _showError("Le mot de passe doit contenir au moins une majuscule et un chiffre");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.register)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': _nameController.text.trim(),
          'age': _age,
          'email': _emailController.text.trim(),
          'motDePasse': _passwordController.text,
          'typeUtilisateur': 'joueur',
          'pseudo': _generatePseudoFromName(_nameController.text.trim()),
          'pays': 'Bénin', // Vous pouvez ajouter un champ pour ça plus tard
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inscription réussie !'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final error = jsonDecode(response.body);
        _showError(error['message'] ?? 'Erreur lors de l\'inscription');
      }
    } catch (e) {
      _showError('Erreur de connexion au serveur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper pour générer un pseudo à partir du nom
  String _generatePseudoFromName(String name) {
    // Retire les espaces et ajoute un nombre aléatoire
    final cleanName = name.replaceAll(' ', '');
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    return '$cleanName$random';
  }

  // Validation de l'email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Vérification majuscule
  bool _hasUpperCase(String text) {
    return RegExp(r'[A-Z]').hasMatch(text);
  }

  // Vérification chiffre
  bool _hasDigit(String text) {
    return RegExp(r'[0-9]').hasMatch(text);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background img_4 (Jaune sur la maquette)
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/backgrounds/img_4.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/logos/logo_1.png',
                width: 180,
              ),
            ),
          ),

          // 2. Carte de formulaire
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text('Inscription', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Veuillez entrer vos données', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 25),

                    // Zone coulissante pour les 2 étapes
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStep1(), // Nom + Âge
                          _buildStep2(), // Email + Password
                        ],
                      ),
                    ),

                    // Indicateurs de progression (petites barres violettes)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildIndicator(_currentStep == 0),
                        const SizedBox(width: 5),
                        _buildIndicator(_currentStep == 1),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Bouton S'inscrire / Suivant
                    ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                        _currentStep == 0 ? 'Suivant' : 'S\'inscrire',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text("ou", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 20),

                    // Bouton Google
                    OutlinedButton.icon(
                      onPressed: () {
                        _showError("Connexion Google non disponible pour le moment");
                      },
                      icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.black),
                      label: const Text('Continuer avec Google', style: TextStyle(color: Colors.black)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6E6AD),
                        minimumSize: const Size(double.infinity, 50),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),

                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Déjà inscrit(e)? Se connecter', style: TextStyle(color: Colors.black54)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return Container(
      width: 25,
      height: 5,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFD1C4E9) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nom', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: _inputStyle('Entrez votre nom ici'),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 20),
        const Text('Âge', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  if (_age > 13) {
                    setState(() => _age--);
                  }
                },
                icon: const Icon(Icons.remove),
              ),
              Text('$_age', style: const TextStyle(fontSize: 18)),
              IconButton(
                onPressed: () {
                  if (_age < 120) {
                    setState(() => _age++);
                  }
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          decoration: _inputStyle('Entrez votre email'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        const Text('Mot de passe', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: _inputStyle('Minimum 8 caractères'),
        ),
        const SizedBox(height: 10),
        const Text(
          'Doit contenir au moins 8 caractères, une majuscule et un chiffre',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }
}