import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart'; // Importa Google Fonts

class RegistrarPacienteDialog extends StatefulWidget {
  const RegistrarPacienteDialog({super.key});

  @override
  State<RegistrarPacienteDialog> createState() => _RegistrarPacienteDialogState();
}

class _RegistrarPacienteDialogState extends State<RegistrarPacienteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  bool _loading = false;
  bool _verPassword = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  // Función para registrar con una instancia secundaria de Firebase
  // Esto es crucial para que el médico pueda registrar pacientes sin desloguearse.
  Future<void> _registrarConFirebaseSecundario({
    required String email,
    required String password,
    required String nombre,
  }) async {
    // Inicializa una app secundaria de Firebase.
    // Esto requiere que el archivo firebase_options.dart esté configurado correctamente
    // para todas las plataformas (web, Android, iOS) y que las credenciales sean válidas.
    FirebaseApp? secApp;
    try {
      secApp = Firebase.app('SecondaryApp');
    } catch (e) {
      // Si la app secundaria no existe, la inicializamos
      secApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options, // Usa las mismas opciones que la app principal
      );
    }

    final secAuth = FirebaseAuth.instanceFor(app: secApp);

    final cred = await secAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Guarda los datos del nuevo paciente en Firestore
    await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'name': nombre,
      'email': email,
      'role': 'paciente', // Rol por defecto 'paciente'
      'createdAt': Timestamp.now(),
    });

    // Importante: Eliminar la app secundaria para liberar recursos.
    // Esto es especialmente relevante en entornos de larga duración como la web.
    await secApp.delete();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    try {
      await _registrarConFirebaseSecundario(
        email: _correoController.text.trim(),
        password: _passwordController.text.trim(),
        nombre: _nombreController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context); // Cierra el diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: colorScheme.onPrimary),
                const SizedBox(width: 10),
                Text(
                  'Paciente registrado correctamente',
                  style: GoogleFonts.inter(color: colorScheme.onPrimary),
                ),
              ],
            ),
            backgroundColor: colorScheme.primary, // Color del tema
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar paciente: ${e.toString()}'),
            backgroundColor: colorScheme.error, // Color de error del tema
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Bordes redondeados
      title: Text(
        "Registrar nuevo paciente",
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView( // Para evitar overflow en pantallas pequeñas o con teclado
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: "Nombre completo",
                  prefixIcon: Icon(Icons.person_outline, color: colorScheme.secondary),
                ),
                style: GoogleFonts.inter(),
                validator: (value) => value == null || value.isEmpty ? "Ingresa un nombre" : null,
              ),
              const SizedBox(height: 20), // Espacio consistente
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Correo electrónico",
                  prefixIcon: Icon(Icons.email_outlined, color: colorScheme.secondary),
                ),
                style: GoogleFonts.inter(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Ingresa un correo";
                  }
                  if (!value.contains('@')) {
                    return "Correo inválido";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: !_verPassword,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: Icon(Icons.lock_outline, color: colorScheme.secondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _verPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: colorScheme.onSurfaceVariant, // Color del icono
                    ),
                    onPressed: () => setState(() => _verPassword = !_verPassword),
                  ),
                ),
                style: GoogleFonts.inter(),
                validator: (value) =>
                    value != null && value.length >= 6 ? null : "Mínimo 6 caracteres",
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmarPasswordController,
                obscureText: !_verPassword, // Mantener la visibilidad consistente
                decoration: InputDecoration(
                  labelText: "Confirmar contraseña",
                  prefixIcon: Icon(Icons.lock_reset_outlined, color: colorScheme.secondary),
                ),
                style: GoogleFonts.inter(),
                validator: (value) =>
                    value == _passwordController.text ? null : "Las contraseñas no coinciden",
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurfaceVariant, // Color del tema
            textStyle: textTheme.labelLarge,
          ),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _registrar,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            textStyle: textTheme.labelLarge,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: colorScheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
              : const Text("Registrar"),
        ),
      ],
      actionsAlignment: MainAxisAlignment.end, // Alinear botones a la derecha
    );
  }
}