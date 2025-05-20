import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chela_medic_web/firebase_options.dart';
import 'package:chela_medic_web/router.dart'; // 🔹 Router central

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
    return MaterialApp.router( // Usa MaterialApp.router aquí
      title: 'Panel Médico - chelaMedic',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      routerConfig: appRouter, // Y configura el router aquí
      debugShowCheckedModeBanner: false,
    );
  }
}

// REMOVE THE AuthGate CLASS FROM HERE.
// It is no longer needed as its logic is handled by GoRouter's redirect.
