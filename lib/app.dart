import 'screens/pacientes_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'layout/main_layout.dart';
import 'screens/dashboard_screen.dart';
import 'screens/configuracion_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const MainLayout(child: DashboardScreen()),
        ),
        GoRoute(
          path: '/pacientes',
          builder: (context, state) => const MainLayout(child: PacientesScreen()),
        ),
        GoRoute(
          path: '/configuracion',
          builder: (context, state) => const MainLayout(child: ConfiguracionScreen()),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Panel Médico',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      routerConfig: _router,
    );
  }
}
