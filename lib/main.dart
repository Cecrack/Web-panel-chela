import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chela_medic_web/firebase_options.dart';
import 'package:chela_medic_web/router.dart'; // 🔹 Router central
import 'package:google_fonts/google_fonts.dart'; // Importa Google Fonts

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RootApp());
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos nuestra paleta de colores moderna (igual que en la app móvil)
    final ColorScheme customColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.teal, // Tu color principal
      brightness: Brightness.light,
      primary: Colors.teal.shade700, // Un teal más profundo
      onPrimary: Colors.white,
      secondary: Colors.amber.shade600, // Un color de acento vibrante
      onSecondary: Colors.white,
      surface: Colors.white, // Color de superficie para la mayoría de los fondos
      onSurface: Colors.grey.shade900, // Color de texto principal sobre superficie
      background: Colors.white,
      onBackground: Colors.grey.shade900,
      error: Colors.red.shade700,
      onError: Colors.white,
      outline: Colors.grey.shade400, // Un gris para los bordes
      surfaceVariant: Colors.teal.shade50, // Un tono muy claro del primario para fondos sutiles
      onSurfaceVariant: Colors.grey.shade700,
    );

    return MaterialApp.router(
      title: 'Panel Médico - chelaMedic',
      theme: ThemeData(
        colorScheme: customColorScheme, // Usa tu paleta de colores definida
        useMaterial3: true, // Habilita Material 3 para widgets más modernos
        fontFamily: GoogleFonts.inter().fontFamily, // Fuente por defecto para toda la app

        // Define los estilos de texto globalmente
        textTheme: TextTheme(
          displayLarge: GoogleFonts.poppins(fontSize: 57, fontWeight: FontWeight.bold, color: customColorScheme.onBackground),
          displayMedium: GoogleFonts.poppins(fontSize: 45, fontWeight: FontWeight.bold, color: customColorScheme.onBackground),
          headlineLarge: GoogleFonts.poppins(fontSize: 38, fontWeight: FontWeight.bold, color: customColorScheme.onBackground),
          headlineMedium: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: customColorScheme.onBackground),
          titleLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: customColorScheme.onBackground),
          titleMedium: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500, color: customColorScheme.onBackground),
          bodyLarge: GoogleFonts.inter(fontSize: 16, color: customColorScheme.onBackground),
          bodyMedium: GoogleFonts.inter(fontSize: 14, color: customColorScheme.onBackground),
          labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: customColorScheme.onBackground),
        ),

        // Estilos para los ElevatedButtons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16.0), // Más padding para web
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            backgroundColor: customColorScheme.primary,
            foregroundColor: customColorScheme.onPrimary,
            elevation: 5,
            textStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),

        // Estilos para los TextButtons
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            foregroundColor: customColorScheme.secondary,
            textStyle: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),

        // Estilos para los TextFormField (InputDecorationTheme)
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: customColorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: customColorScheme.outline.withOpacity(0.6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: customColorScheme.primary, width: 2.0),
          ),
          filled: true,
          fillColor: customColorScheme.surfaceVariant.withOpacity(0.3),
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          labelStyle: GoogleFonts.inter(color: customColorScheme.onSurfaceVariant),
          hintStyle: GoogleFonts.inter(color: customColorScheme.onSurfaceVariant.withOpacity(0.6)),
          prefixIconColor: customColorScheme.secondary,
        ),

        // Estilos para Card (si usas Card en tu app)
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          color: customColorScheme.surface,
        ),
        // Puedes añadir más temas para otros widgets si es necesario
      ),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}