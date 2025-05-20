// lib/screens/citas_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  String? _pacienteSeleccionadoId;
  String? _pacienteSeleccionadoNombre;
  final _motivoController = TextEditingController();
  DateTime? _fechaSeleccionada;

  void _crearCita() async {
    if (_pacienteSeleccionadoId == null ||
        _motivoController.text.isEmpty ||
        _fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_pacienteSeleccionadoId)
        .collection('citas')
        .add({
      'motivo': _motivoController.text.trim(),
      'fecha': Timestamp.fromDate(_fechaSeleccionada!),
      'creadoPorMedico': true,
      'creadoEn': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cita creada exitosamente')),
    );

    _motivoController.clear();
    _fechaSeleccionada = null;
    Navigator.pop(context);
  }

  void _mostrarDialogoNuevaCita() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva cita médica'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _motivoController,
              decoration: const InputDecoration(labelText: 'Motivo'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final seleccionada = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (seleccionada != null) {
                  setState(() => _fechaSeleccionada = seleccionada);
                }
              },
              child: const Text('Seleccionar fecha'),
            ),
            if (_fechaSeleccionada != null)
              Text("Fecha: ${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _crearCita,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Color _estadoColor(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = fecha.difference(ahora);
    if (diferencia.inHours < 0) return Colors.red; // cita pasada
    if (diferencia.inHours <= 24) return Colors.orange; // menos de 24 horas
    return Colors.green; // futura
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Citas Médicas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Seleccionar paciente:"),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'paciente')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final pacientes = snapshot.data!.docs;
                return DropdownButton<String>(
                  isExpanded: true,
                  value: _pacienteSeleccionadoId,
                  hint: const Text("Selecciona un paciente"),
                  items: pacientes.map((doc) {
                    final nombre = doc['name'];
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(nombre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _pacienteSeleccionadoId = value;
                      _pacienteSeleccionadoNombre = pacientes
                          .firstWhere((doc) => doc.id == value)['name'];
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            if (_pacienteSeleccionadoId != null)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_pacienteSeleccionadoId)
                      .collection('citas')
                      .orderBy('fecha')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final citas = snapshot.data!.docs;
                    if (citas.isEmpty) {
                      return const Text("Este paciente no tiene citas registradas.");
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Citas de $_pacienteSeleccionadoNombre", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: citas.length,
                            itemBuilder: (context, index) {
                              final data = citas[index].data() as Map<String, dynamic>;
                              final fecha = (data['fecha'] as Timestamp).toDate();
                              final estadoColor = _estadoColor(fecha);
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: Icon(Icons.circle, color: estadoColor, size: 14),
                                  title: Text(data['motivo'] ?? 'Sin motivo'),
                                  subtitle: Text("${fecha.day}/${fecha.month}/${fecha.year}"),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _pacienteSeleccionadoId != null
          ? FloatingActionButton.extended(
              onPressed: _mostrarDialogoNuevaCita,
              label: const Text("Agregar cita"),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}
