import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importa Firestore
import 'layout/main_layout.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pacientes_screen.dart';
import 'screens/configuracion_screen.dart';
import 'screens/citas_screen.dart';
import 'screens/medicamentos_screen.dart';
import 'screens/login_screen.dart'; // Asegúrate de que esta importación sea correcta

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  // Usa la función de redirección para manejar la autenticación
  redirect: (context, state) async {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final bool isLoggingIn = state.matchedLocation == '/login'; // Comprueba la ruta directamente

    // Si no está logueado, redirige a la página de login, a menos que ya esté en ella.
    if (!isLoggedIn && !isLoggingIn) {
      return '/login';
    }

    // Si está logueado e intenta ir a la página de login, redirige al dashboard.
    if (isLoggedIn && isLoggingIn) {
      return '/';
    }

    // Para cualquier otra ruta, permite el acceso.  Esto es importante.
    return null;
  },
  routes: [
    // Define la ruta para la pantalla de inicio de sesión
    GoRoute(
      name: 'login',
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      name: 'dashboard',
      path: '/',
      builder: (context, state) => const MainLayout(
        currentRoute: '/',
        child: DashboardScreen(),
      ),
    ),
    GoRoute(
      name: 'pacientes',
      path: '/pacientes',
      builder: (context, state) => const MainLayout(
        currentRoute: '/pacientes',
        child: PacientesScreen(),
      ),
    ),
    GoRoute(
      name: 'configuracion',
      path: '/configuracion',
      builder: (context, state) => const MainLayout(
        currentRoute: '/configuracion',
        child: ConfiguracionScreen(),
      ),
    ),
     GoRoute(
      name: 'citas',
      path: '/citas',
      builder: (context, state) => const MainLayout(
        currentRoute: '/citas',
        child: CitasScreen(),
      ),
    ),
    GoRoute(
      name: 'medicamentos',
      path: '/medicamentos',
      builder: (context, state) => const MainLayout(
        currentRoute: '/medicamentos',
        child: MedicamentosScreen(),
      ),
    ),
  ],
);
