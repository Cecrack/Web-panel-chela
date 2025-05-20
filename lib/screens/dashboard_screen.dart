// lib/screens/dashboard_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio - Panel Médico')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _registrarPaciente(context),
          icon: const Icon(Icons.person_add),
          label: const Text("Registrar nuevo paciente"),
        ),
      ),
    );
  }
}

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

  Future<void> _registrarConFirebaseSecundario({
    required String email,
    required String password,
    required String nombre,
  }) async {
    final secApp = await Firebase.initializeApp(
      name: 'SecondaryApp',
      options: Firebase.app().options,
    );

    final secAuth = FirebaseAuth.instanceFor(app: secApp);

    final cred = await secAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'name': nombre,
      'email': email,
      'role': 'paciente',
    });

    await secApp.delete();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _registrarConFirebaseSecundario(
        email: _correoController.text.trim(),
        password: _passwordController.text.trim(),
        nombre: _nombreController.text.trim(),
      );

      if (mounted) {
  Navigator.pop(context);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text(
        '✅ Paciente registrado correctamente',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Registrar nuevo paciente"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: "Nombre completo"),
              validator: (value) => value == null || value.isEmpty ? "Ingresa un nombre" : null,
            ),
            TextFormField(
              controller: _correoController,
              decoration: const InputDecoration(labelText: "Correo"),
              validator: (value) => value == null || value.isEmpty ? "Ingresa un correo" : null,
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: !_verPassword,
              decoration: InputDecoration(
                labelText: "Contraseña",
                suffixIcon: IconButton(
                  icon: Icon(_verPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _verPassword = !_verPassword),
                ),
              ),
              validator: (value) =>
                  value != null && value.length >= 6 ? null : "Mínimo 6 caracteres",
            ),
            TextFormField(
              controller: _confirmarPasswordController,
              obscureText: !_verPassword,
              decoration: const InputDecoration(labelText: "Confirmar contraseña"),
              validator: (value) =>
                  value == _passwordController.text ? null : "Las contraseñas no coinciden",
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _registrar,
          child: _loading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : const Text("Registrar"),
        ),
      ],
    );
  }
}
