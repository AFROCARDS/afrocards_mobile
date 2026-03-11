import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/providers/user_state_provider.dart';
import 'core/providers/theme_provider.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

/// 🚀 MAIN.DART - AFROCARDS
/// Point d'entrée de l'application

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 Configuration de l'orientation (Portrait uniquement)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 🎨 Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AfroCardsApp());
}

class AfroCardsApp extends StatelessWidget {
  const AfroCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserStateProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'AFROCARDS',
            debugShowCheckedModeBanner: false,
            
            // 🎨 Thèmes
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,

            // 🏠 Route de démarrage
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}