import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'package:google_fonts/google_fonts.dart'; // Importa Google Fonts

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isLoading = false; // Para controlar el estado de carga

  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true; // Activar indicador de carga
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (context.mounted) {
          GoRouter.of(context).go('/'); // Redirigir a la ruta raíz
        }
      } else {
        // Lógica de registro para médicos en la versión web
        final nombre = _nombreController.text.trim();
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'name': nombre,
          'email': email,
          'role': 'medico', // Asignar rol de médico por defecto en el registro web
          'createdAt': Timestamp.now(),
        });
        if (context.mounted) {
          GoRouter.of(context).go('/'); // Redirigir a la ruta raíz
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false; // Desactivar indicador de carga
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Usar colores del tema para el fondo
      backgroundColor: colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450), // Aumentar un poco el ancho
            padding: const EdgeInsets.all(32), // Aumentar el padding interno
            decoration: BoxDecoration(
              color: colorScheme.surface, // Color de superficie del tema
              borderRadius: BorderRadius.circular(24), // Bordes más redondeados
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.15), // Sombra más sutil y del tema
                  blurRadius: 20, // Mayor blur
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono y Título de la App
                  Icon(
                    Icons.medical_services_rounded, // Icono más relevante
                    size: 80,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'chelaMedic Panel',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins( // Fuente y estilo del tema
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Accede a tu cuenta de médico' : 'Crea tu cuenta de médico',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 40),

                  // Campos del formulario
                  if (!_isLogin)
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline, color: colorScheme.secondary),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Ingrese su nombre' : null,
                    ),
                  if (!_isLogin) const SizedBox(height: 20), // Espacio consistente

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined, color: colorScheme.secondary),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese su correo';
                      }
                      if (!value.contains('@')) {
                        return 'Correo inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline, color: colorScheme.secondary),
                    ),
                    validator: (value) =>
                        value == null || value.length < 6
                            ? 'Mínimo 6 caracteres'
                            : null,
                  ),
                  const SizedBox(height: 20),

                  if (!_isLogin)
                    TextFormField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: Icon(Icons.lock_reset_outlined, color: colorScheme.secondary),
                      ),
                      validator: (value) =>
                          value != _passwordController.text
                              ? 'Las contraseñas no coinciden'
                              : null,
                    ),
                  if (!_isLogin) const SizedBox(height: 30), // Espacio consistente

                  // Botón de Submit
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit, // Deshabilitar si está cargando
                    icon: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(_isLogin ? Icons.login : Icons.person_add),
                    label: Text(_isLogin ? 'Iniciar sesión' : 'Registrarse'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56), // Botón más grande
                      textStyle: textTheme.labelLarge?.copyWith(fontSize: 18), // Texto más grande
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón para cambiar entre Login y Registro
                  TextButton(
                    onPressed: _isLoading ? null : () { // Deshabilitar si está cargando
                      setState(() {
                        _isLogin = !_isLogin;
                        _formKey.currentState?.reset(); // Limpiar validación al cambiar
                        _nombreController.clear(); // Limpiar campos
                        _emailController.clear();
                        _passwordController.clear();
                        _confirmController.clear();
                      });
                    },
                    child: Text(
                      _isLogin
                          ? '¿No tienes cuenta? Regístrate aquí'
                          : '¿Ya tienes cuenta? Inicia sesión',
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.secondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}