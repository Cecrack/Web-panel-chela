import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        return Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(title: const Text('Panel Médico')),
          drawer: isDesktop ? null : _buildDrawer(context),
          body: Row(
            children: [
              if (isDesktop) _buildDrawer(context),
              Expanded(
                child: Container(
                  color: Colors.grey[100],
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Panel Médico',
              style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          _buildDrawerItem(context, icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/'),
          _buildDrawerItem(context, icon: Icons.people_alt_outlined, label: 'Pacientes', route: '/pacientes'),
          _buildDrawerItem(context, icon: Icons.calendar_today_outlined, label: 'Citas', route: '/citas'),
          _buildDrawerItem(context, icon: Icons.medication_outlined, label: 'Medicamentos', route: '/medicamentos'),
          _buildDrawerItem(context, icon: Icons.settings_outlined, label: 'Configuración', route: '/configuracion'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.go('/login'); // Ajusta la ruta si tu login está en otra.
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[800]),
      title: Text(label, style: const TextStyle(fontSize: 16)),
      onTap: () => context.go(route),
      hoverColor: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
