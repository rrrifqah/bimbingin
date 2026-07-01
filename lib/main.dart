import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/bimbingan_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/progres_provider.dart';
import 'providers/target_provider.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BimbinganProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProgresProvider()),
        ChangeNotifierProvider(create: (_) => TargetProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bimbingin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B4FE4),
          primary: const Color(0xFF3B4FE4),
          secondary: const Color(0xFF6C63FF),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
