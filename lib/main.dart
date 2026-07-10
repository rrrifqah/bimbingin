import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/bimbingan_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/progres_provider.dart';
import 'providers/target_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/jadwal_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  await Supabase.initialize(
    url: 'https://ihjaeolsecdvegwfdmvf.supabase.co',
    publishableKey: 'sb_publishable_Mi-6Gv1vD5R2CzHskKvq-g_pZd9iDFy',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BimbinganProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProgresProvider()),
        ChangeNotifierProvider(create: (_) => TargetProvider()),
        // BookingProvider dan JadwalProvider didaftarkan agar bisa diakses global
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => JadwalProvider()),
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
          seedColor: const Color(0xFF39A846),
          primary: const Color(0xFF39A846),
          secondary: const Color(0xFF2D6A4F),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
