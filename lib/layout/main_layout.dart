import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:badges/badges.dart' as badges;
import 'package:rxdart/rxdart.dart';
import 'package:google_fonts/google_fonts.dart';

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
  late CompositeSubscription _subscriptions;
  
  String? _medicoUid;
  String? _medicoEmail;
  String? _medicoName;

  @override
  void initState() {
    super.initState();
    _subscriptions = CompositeSubscription();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _medicoUid = user.uid;
      _medicoEmail = user.email;

      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(_medicoUid).get();
        if (doc.exists && doc.data() != null && doc.data()!['name'] != null) {
          _medicoName = doc.data()!['name'] as String;
        } else {
          _medicoName = 'Médico';
        }
      } catch (e) {
        print('Error fetching user name: $e');
        _medicoName = 'Médico';
      }

      print('Logged in user UID: $_medicoUid');
      _initNotificationStream();
      setState(() {});
    } else {
      print("ERROR: MainLayout construido sin un usuario logueado. Redirigiendo...");
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  void _initNotificationStream() {
    if (_medicoUid == null) {
      print("Error: _medicoUid es nulo en _initNotificationStream. No se inicializan los streams.");
      return;
    }

    final Stream<QuerySnapshot> requestedCitasStream = FirebaseFirestore.instance
        .collection('citas')
        .where('estado', isEqualTo: 'solicitada')
        .snapshots();

    final Stream<QuerySnapshot> pendingCitasStream = FirebaseFirestore.instance
        .collection('citas')
        .where('medicoId', isEqualTo: _medicoUid)
        .where('estado', isEqualTo: 'pendiente')
        .snapshots();

    _subscriptions.add(
      Rx.combineLatest2(
        requestedCitasStream,
        pendingCitasStream,
        (QuerySnapshot requestedSnapshot, QuerySnapshot pendingSnapshot) {
          return requestedSnapshot.docs.length + pendingSnapshot.docs.length;
        },
      ).listen((totalCount) {
        if (mounted) {
          setState(() {
            _notificationCount = totalCount;
          });
        }
      }, onError: (error) {
        print("Error en stream de notificaciones: $error");
      })
    );
  }

  @override
  void dispose() {
    _subscriptions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_medicoUid == null) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 20),
              Text('Cargando datos del médico...', style: textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text('chelaMedic', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: colorScheme.onPrimary)),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              actions: [
                _buildNotificationButton(context, isDesktop),
              ],
            ),
      drawer: isDesktop ? null : _buildDrawer(context),
      body: Row(
        children: [
          if (isDesktop) _buildDrawer(context),
          Expanded(
            child: Container(
              color: colorScheme.surface,
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
      floatingActionButton: isDesktop ? _buildNotificationButton(context, isDesktop) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }

  Widget _buildNotificationButton(BuildContext context, bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, right: 8.0),
      child: badges.Badge(
        badgeContent: Text(
          _notificationCount.toString(),
          style: TextStyle(color: colorScheme.onPrimary),
        ),
        showBadge: _notificationCount > 0,
        position: badges.BadgePosition.topEnd(top: -5, end: -5),
        badgeStyle: badges.BadgeStyle(
          badgeColor: colorScheme.error,
          padding: const EdgeInsets.all(6),
        ),
        child: FloatingActionButton(
          onPressed: () {
            GoRouter.of(context).go('/citas');
          },
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          elevation: 6,
          mini: !isDesktop,
          child: const Icon(Icons.notifications),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Drawer(
      backgroundColor: colorScheme.surface,
      width: isDesktop ? 250 : null,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.onPrimary,
                  child: Icon(
                    Icons.medical_services_rounded,
                    size: 36,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _medicoName ?? 'Médico',
                  style: GoogleFonts.poppins(
                    color: colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _medicoEmail ?? 'Cargando...',
                  style: GoogleFonts.poppins(
                    color: colorScheme.onPrimary.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  route: '/',
                  isActive: widget.currentRoute == '/',
                  isDesktop: isDesktop,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people_alt_rounded,
                  label: 'Pacientes',
                  route: '/pacientes',
                  isActive: widget.currentRoute == '/pacientes',
                  isDesktop: isDesktop,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.calendar_today_rounded,
                  label: 'Citas',
                  route: '/citas',
                  isActive: widget.currentRoute == '/citas',
                  isDesktop: isDesktop,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.medication_rounded,
                  label: 'Medicamentos',
                  route: '/medicamentos',
                  isActive: widget.currentRoute == '/medicamentos',
                  isDesktop: isDesktop,
                ),
                // Eliminada la sección de Reportes
                // Eliminado el Divider antes de la sección de Reportes
                // Eliminados los ListTiles de Reporte de Cumplimiento y Reporte de Signos Vitales

                Divider(indent: 16, endIndent: 16, color: colorScheme.outlineVariant),
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: colorScheme.error),
                  title: Text('Cerrar sesión', style: textTheme.titleMedium?.copyWith(color: colorScheme.error)),
                  onTap: () async {
                    if (!isDesktop && context.mounted) Navigator.of(context).pop();
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String route,
        bool isActive = false,
        bool isDesktop = false,
        String? badgeContent,
      }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: isActive
          ? BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
          ),
        ),
        trailing: badgeContent != null
            ? badges.Badge(
                badgeContent: Text(
                  badgeContent,
                  style: TextStyle(color: colorScheme.onError),
                ),
                badgeStyle: badges.BadgeStyle(
                  badgeColor: colorScheme.error,
                  padding: const EdgeInsets.all(5),
                ),
              )
            : null,
        onTap: () {
          if (!isDesktop && context.mounted) {
            Navigator.of(context).pop();
          }
          GoRouter.of(context).go(route);
        },
        hoverColor: colorScheme.primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}