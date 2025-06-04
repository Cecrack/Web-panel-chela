// lib/screens/dashboard_screen.dart

import 'package:chela_medic_web/RegistrarPacienteDialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Importa Google Fonts
import 'package:go_router/go_router.dart'; // Importa GoRouter

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _registrarPaciente(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const RegistrarPacienteDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        title: Text(
          'Panel Médico - chelaMedic',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        // Opcional: Aquí puedes agregar un botón de logout si el GoRouter no lo maneja globalmente
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout_rounded),
        //     tooltip: 'Cerrar Sesión',
        //     onPressed: () async {
        //       await FirebaseAuth.instance.signOut();
        //       GoRouter.of(context).go('/login'); // O la ruta de tu pantalla de login
        //     },
        //   ),
        //   const SizedBox(width: 8),
        // ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard_rounded, // Icono representativo del dashboard
              size: 100,
              color: colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Bienvenido al Panel de Administración',
              style: textTheme.headlineMedium?.copyWith(color: colorScheme.onBackground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Gestiona tus pacientes y sus datos de salud.',
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _registrarPaciente(context),
              icon: const Icon(Icons.person_add_alt_1_rounded), // Icono más moderno
              label: Text(
                "Registrar nuevo paciente",
                style: textTheme.labelLarge?.copyWith(fontSize: 18), // Hereda estilo del tema
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18), // Más padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15), // Bordes más redondeados
                ),
                elevation: 8, // Mayor sombra
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
            // Puedes agregar más botones o secciones aquí para otras funcionalidades del médico
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navegar a la pantalla de gestión de pacientes
                // En lugar del SnackBar, navegamos con GoRouter
                GoRouter.of(context).go('/pacientes'); // ¡Aquí está la solución!
              },
              icon: const Icon(Icons.people_alt_rounded),
              label: Text(
                "Ver y Gestionar Pacientes",
                style: textTheme.labelLarge?.copyWith(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 8,
                backgroundColor: colorScheme.surfaceVariant, // Un color secundario
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}