import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/router/app_router.dart';
import 'core/signals/app_signals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Force Landscape Mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize signals and database
  await initAppSignals();

  runApp(const DoraebinApp());
}

class DoraebinApp extends StatelessWidget {
  const DoraebinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Doraebin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF776300),
          surface: const Color(0xFFFFF6A5),
          primary: const Color(0xFF776300),
          secondary: const Color(0xFF006C95),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFBF0),
        useMaterial3: true,
        textTheme: GoogleFonts.beVietnamProTextTheme(),
      ),
      routerConfig: appRouter,
    );
  }
}
