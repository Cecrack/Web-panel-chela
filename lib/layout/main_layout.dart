import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:badges/badges.dart' as badges;

class MainLayout extends StatefulWidget {
  final Widget child;
  final String? currentRoute;

  const MainLayout({Key? key, required this.child, this.currentRoute})
      : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _notificationCount = 0;
  Stream<QuerySnapshot>? _notificationStream;
  String? _medicoUid; // Almacena el UID del médico logueado

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Carga los datos del usuario al iniciar el estado
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _medicoUid = user.uid;
      print('Logged in user UID: $_medicoUid'); // Para depuración
      _initNotificationStream();
    } else {
      print(
          "ERROR: MainLayout construido sin un usuario logueado. Esto no debería suceder.");
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  // Método para inicializar el stream de notificaciones
  void _initNotificationStream() {
    if (_medicoUid == null) {
      print(
          "Error: _medicoUid es nulo en _initNotificationStream. Esto no debería suceder.");
      return;
    }
    final Stream<QuerySnapshot> requestedCitasStream = FirebaseFirestore.instance
        .collection('citas')
        .where('estado', isEqualTo: 'solicitada')
        .snapshots();

    // Stream 2: Citas pendientes asignadas a este médico
    final Stream<QuerySnapshot> pendingCitasStream = FirebaseFirestore.instance
        .collection('citas')
        .where('medicoId', isEqualTo: _medicoUid) // Filtra por el UID del médico actual
        .where('estado', isEqualTo: 'pendiente') // Filtra por citas pendientes
        .snapshots();
    _notificationCount = 0;

    // Escucha el stream de solicitudes
    requestedCitasStream.listen((snapshot) {
      if (mounted) {
        setState(() {
       
          _notificationCount = snapshot.docs.length; // Comienza con las solicitudes
          // Y luego añade las pendientes (se actualizarán con el segundo listener)
        });
      }
    });

    // Escucha el stream de citas pendientes asignadas
    pendingCitasStream.listen((snapshot) {
      if (mounted) {
        setState(() {
          // Suma al contador existente (desde las solicitudes)
          _notificationCount += snapshot.docs.length;
        });
      }
    });
  }

  @override
  void dispose() {
  
    _notificationStream?.listen((_) {}).cancel(); // Esto cancela el último asignado.

  

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    // Muestra un indicador de carga si el UID del médico aún no está disponible
    if (_medicoUid == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: isDesktop ? null : AppBar(title: const Text('Panel Médico')),
      drawer: isDesktop ? null : _buildDrawer(context),
      body: Row(
        children: [
          if (isDesktop) _buildDrawer(context),
          Expanded(
            child: Container(
              color: Colors.grey[100],
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 24,
                vertical: 24,
              ),
              child: Card(
                elevation: 4,
                margin: isDesktop
                    ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
                    : EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      ),
      // Solo muestra el botón de notificación en el modo de escritorio (Desktop)
      floatingActionButton: isDesktop ? _buildNotificationButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }

  // Función para construir el botón de notificaciones
  Widget _buildNotificationButton() {
    // El StreamBuilder aquí está usando el _notificationStream asignado al último listener.
    // Si tienes múltiples listeners como lo hice arriba, el _notificationCount
    // se actualizará desde ambos, y el StreamBuilder aquí reflejará el valor final.
    // Sin embargo, una mejor práctica sería tener un solo Stream<int> combinado.
    return badges.Badge(
      badgeContent: Text(
        _notificationCount.toString(),
        style: const TextStyle(color: Colors.white),
      ),
      showBadge: _notificationCount > 0, // Solo muestra el badge si hay notificaciones
      position: badges.BadgePosition.topEnd(top: 0, end: 3),
      child: FloatingActionButton(
        onPressed: () {
          // Navega a la ruta de las citas. No es necesario pasar 'extra' aquí
          // si la pantalla de citas carga sus propios datos de Firestore.
          GoRouter.of(context).go('/citas');
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.notifications),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Center(
              child: Text(
                'Panel Médico',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDrawerItem(
            context,
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: '/',
            isActive: widget.currentRoute == '/',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.people_alt_outlined,
            label: 'Pacientes',
            route: '/pacientes',
            isActive: widget.currentRoute == '/pacientes',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.calendar_today_outlined,
            label: 'Citas',
            route: '/citas',
            isActive: widget.currentRoute == '/citas',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.medication_outlined,
            label: 'Medicamentos',
            route: '/medicamentos',
            isActive: widget.currentRoute == '/medicamentos',
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  // Función para construir los elementos del Drawer
  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String route,
        bool isActive = false,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? Colors.blue[800] : Colors.grey[600],
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        context.go(route);
      },
      hoverColor: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}