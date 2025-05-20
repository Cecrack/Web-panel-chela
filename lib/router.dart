import 'package:go_router/go_router.dart';
import 'layout/main_layout.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pacientes_screen.dart';
import 'screens/configuracion_screen.dart';
import 'screens/citas_screen.dart'; // 👈 Asegúrate de importar esto
import 'screens/medicamentos_screen.dart'; // 👈 Asegúrate de importar esto

final GoRouter appRouter = GoRouter(
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
    GoRoute(
      path: '/citas',
      builder: (context, state) => const MainLayout(child: CitasScreen()),
    ),
    GoRoute(
      path: '/medicamentos',
      builder: (context, state) => const MainLayout(child: MedicamentosScreen()),
    ),
  ],
);
