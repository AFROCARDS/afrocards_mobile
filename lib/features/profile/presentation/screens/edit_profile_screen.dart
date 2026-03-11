import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';

/// Liste d'avatars disponibles (images en ligne)
const List<String> availableAvatars = [
  'https://api.dicebear.com/7.x/avataaars/png?seed=Felix&backgroundColor=b6e3f4',
  'https://api.dicebear.com/7.x/avataaars/png?seed=Aneka&backgroundColor=c0aede',
  'https://api.dicebear.com/7.x/avataaars/png?seed=Michael&backgroundColor=d1d4f9',
  'https://api.dicebear.com/7.x/avataaars/png?seed=Sophie&backgroundColor=ffd5dc',
  'https://api.dicebear.com/7.x/avataaars/png?seed=Leo&backgroundColor=ffdfbf',
  'https://api.dicebear.com/7.x/avataaars/png?seed=Emma&backgroundColor=c1f4c5',
  'https://api.dicebear.com/7.x/avataaars/png?seed=Lucas&backgroundColor=b6e3f4',
  'https://api.dicebear.com/7.x/avataaars/png?seed=Chloe&backgroundColor=c0aede',
  'https://api.dicebear.com/7.x/avataaars/png?seed=Noah&backgroundColor=d1d4f9',
  'https://api.dicebear.com/7.x/avataaars/png?seed=Jade&backgroundColor=ffd5dc',
  'https://api.dicebear.com/7.x/avataaars/png?seed=Adam&backgroundColor=ffdfbf',
  'https://api.dicebear.com/7.x/avataaars/png?seed=Maya&backgroundColor=c1f4c5',
  'https://api.dicebear.com/7.x/lorelei/png?seed=Afro1&backgroundColor=b6e3f4',
  'https://api.dicebear.com/7.x/lorelei/png?seed=Afro2&backgroundColor=c0aede',
  'https://api.dicebear.com/7.x/lorelei/png?seed=Afro3&backgroundColor=d1d4f9',
  'https://api.dicebear.com/7.x/lorelei/png?seed=Afro4&backgroundColor=ffd5dc',
  'https://api.dicebear.com/7.x/notionists/png?seed=Player1&backgroundColor=b6e3f4',
  'https://api.dicebear.com/7.x/notionists/png?seed=Player2&backgroundColor=c0aede',
  'https://api.dicebear.com/7.x/notionists/png?seed=Player3&backgroundColor=d1d4f9',
  'https://api.dicebear.com/7.x/notionists/png?seed=Player4&backgroundColor=ffd5dc',
];

/// Liste des nationalités africaines
const List<String> africanNationalities = [
  'Algérie', 'Angola', 'Bénin', 'Botswana', 'Burkina Faso',
  'Burundi', 'Cameroun', 'Cap-Vert', 'Centrafrique', 'Comores',
  'Congo', 'Côte d\'Ivoire', 'Djibouti', 'Égypte', 'Érythrée',
  'Eswatini', 'Éthiopie', 'Gabon', 'Gambie', 'Ghana',
  'Guinée', 'Guinée-Bissau', 'Guinée équatoriale', 'Kenya', 'Lesotho',
  'Libéria', 'Libye', 'Madagascar', 'Malawi', 'Mali',
  'Maroc', 'Maurice', 'Mauritanie', 'Mozambique', 'Namibie',
  'Niger', 'Nigeria', 'Ouganda', 'RD Congo', 'Rwanda',
  'São Tomé-et-Príncipe', 'Sénégal', 'Seychelles', 'Sierra Leone', 'Somalie',
  'Soudan', 'Soudan du Sud', 'Tanzanie', 'Tchad', 'Togo',
  'Tunisie', 'Zambie', 'Zimbabwe'
];

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pseudoController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  final _ancienMdpController = TextEditingController();
  final _nouveauMdpController = TextEditingController();
  final _confirmMdpController = TextEditingController();
  
  String? _selectedNationality;
  String? _selectedAvatar;
  bool _loading = false;
  bool _showPasswordFields = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  void _loadCurrentProfile() {
    final userState = context.read<UserStateProvider>();
    _pseudoController.text = userState.userName;
    _selectedAvatar = userState.avatarUrl;
    // Les autres champs seront chargés depuis le profil API
    _fetchProfileDetails();
  }

  Future<void> _fetchProfileDetails() async {
    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.profile)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profil = data['data']?['profil'] ?? {};
        
        setState(() {
          if (profil['pseudo'] != null) _pseudoController.text = profil['pseudo'];
          if (profil['age'] != null) _ageController.text = profil['age'].toString();
          if (profil['bio'] != null) _bioController.text = profil['bio'] ?? '';
          _selectedNationality = profil['nationalite'];
          _selectedAvatar = profil['avatarURL'];
        });
      }
    } catch (e) {
      debugPrint('Erreur fetch profil: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier les mots de passe si changement demandé
    if (_showPasswordFields) {
      if (_nouveauMdpController.text != _confirmMdpController.text) {
        _showSnackBar('Les mots de passe ne correspondent pas', isError: true);
        return;
      }
      if (_nouveauMdpController.text.length < 6) {
        _showSnackBar('Le mot de passe doit faire au moins 6 caractères', isError: true);
        return;
      }
    }

    setState(() => _loading = true);

    final userState = context.read<UserStateProvider>();
    final token = userState.token;
    if (token == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final body = <String, dynamic>{
        'pseudo': _pseudoController.text.trim(),
        'nationalite': _selectedNationality,
        'avatarURL': _selectedAvatar,
      };

      if (_ageController.text.isNotEmpty) {
        body['age'] = int.tryParse(_ageController.text);
      }
      
      if (_bioController.text.isNotEmpty) {
        body['bio'] = _bioController.text.trim();
      }

      if (_showPasswordFields && _ancienMdpController.text.isNotEmpty) {
        body['ancienMotDePasse'] = _ancienMdpController.text;
        body['motDePasse'] = _nouveauMdpController.text;
      }

      final response = await http.put(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.updateProfile)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Mettre à jour le UserStateProvider
        userState.updateUserInfo(
          userName: _pseudoController.text.trim(),
          avatarUrl: _selectedAvatar,
        );
        
        // Mettre à jour le SessionService (cache profil)
        final session = SessionService.instance;
        final updatedProfile = {
          ...session.profileData ?? {},
          'pseudo': _pseudoController.text.trim(),
          'avatarURL': _selectedAvatar,
          'nationalite': _selectedNationality,
          if (_bioController.text.isNotEmpty) 'bio': _bioController.text.trim(),
        };
        await session.updateProfile(updatedProfile);
        
        _showSnackBar('Profil mis à jour avec succès !');
        
        // Retourner à l'écran précédent
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showSnackBar(data['message'] ?? 'Erreur lors de la mise à jour', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erreur de connexion', isError: true);
    }

    setState(() => _loading = false);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Choisir un avatar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: availableAvatars.length,
                itemBuilder: (context, index) {
                  final avatar = availableAvatars[index];
                  final isSelected = _selectedAvatar == avatar;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAvatar = avatar);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFFB74D) : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: NetworkImage(avatar),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _ancienMdpController.dispose();
    _nouveauMdpController.dispose();
    _confirmMdpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                const AppHeader(
                  title: 'Modifier le profil',
                  centerTitle: true,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Avatar
                          _buildAvatarSection(),
                          const SizedBox(height: 24),
                          
                          // Pseudo
                          _buildTextField(
                            controller: _pseudoController,
                            label: 'Pseudo',
                            icon: Icons.person,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Le pseudo est requis';
                              }
                              if (value.length < 3) {
                                return 'Le pseudo doit faire au moins 3 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Age
                          _buildTextField(
                            controller: _ageController,
                            label: 'Âge',
                            icon: Icons.cake,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final age = int.tryParse(value);
                                if (age == null || age < 13 || age > 120) {
                                  return 'Âge invalide (13-120)';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Nationalité
                          _buildDropdownField(),
                          const SizedBox(height: 16),
                          
                          // Bio
                          _buildTextField(
                            controller: _bioController,
                            label: 'Bio',
                            icon: Icons.edit_note,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                          
                          // Section mot de passe
                          _buildPasswordSection(),
                          const SizedBox(height: 32),
                          
                          // Bouton sauvegarder
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB74D),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Sauvegarder',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showAvatarPicker,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _selectedAvatar != null
                    ? NetworkImage(_selectedAvatar!)
                    : null,
                child: _selectedAvatar == null
                    ? const Icon(Icons.person, color: Colors.white, size: 50)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Appuyez pour changer l\'avatar',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFFFB74D)),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: context.colors.cardBackground,
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedNationality,
        decoration: InputDecoration(
          labelText: 'Nationalité',
          prefixIcon: const Icon(Icons.flag, color: Color(0xFFFFB74D)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: context.colors.cardBackground,
        ),
        items: africanNationalities.map((nationality) {
          return DropdownMenuItem<String>(
            value: nationality,
            child: Text(nationality),
          );
        }).toList(),
        onChanged: (value) {
          setState(() => _selectedNationality = value);
        },
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: const Text('Changer le mot de passe'),
        leading: const Icon(Icons.lock, color: Color(0xFFFFB74D)),
        onExpansionChanged: (expanded) {
          setState(() => _showPasswordFields = expanded);
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTextField(
                  controller: _ancienMdpController,
                  label: 'Ancien mot de passe',
                  icon: Icons.lock_outline,
                  obscureText: _obscureOldPassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOldPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _nouveauMdpController,
                  label: 'Nouveau mot de passe',
                  icon: Icons.lock,
                  obscureText: _obscureNewPassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _confirmMdpController,
                  label: 'Confirmer le mot de passe',
                  icon: Icons.lock_clock,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
