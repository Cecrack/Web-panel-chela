import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chela_medic_web/firebase_options.dart';
import 'package:chela_medic_web/screens/login_screen.dart';
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
    return MaterialApp(
      title: 'Panel Médico - chelaMedic',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final uid = snapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final role = userSnapshot.data!.get('role');
            if (role == 'medico') {
              // 🔹 Devuelve app con router
              return MaterialApp.router(
                title: 'Panel Médico',
                theme: ThemeData(
                  useMaterial3: true,
                  colorSchemeSeed: Colors.teal,
                ),
                routerConfig: appRouter,
              );
            } else {
              return const Scaffold(
                body: Center(child: Text('Acceso restringido al panel médico')),
              );
            }
          },
        );
      },
    );
  }
}
