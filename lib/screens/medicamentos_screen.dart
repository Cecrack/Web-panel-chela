// lib/screens/medicamentos_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicamentosScreen extends StatefulWidget {
  const MedicamentosScreen({super.key});

  @override
  State<MedicamentosScreen> createState() => _MedicamentosScreenState();
}

class _MedicamentosScreenState extends State<MedicamentosScreen> {
  String? _pacienteSeleccionadoId;
  String? _pacienteSeleccionadoNombre;

  final _medicamentoController = TextEditingController();
  final _dosisController = TextEditingController();
  final _frecuenciaHorasController = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _medicamentoIdEditando;

  Future<void> _asignarMedicamento() async {
    if (_medicamentoController.text.isEmpty ||
        _dosisController.text.isEmpty ||
        _frecuenciaHorasController.text.isEmpty ||
        _fechaInicio == null ||
        _fechaFin == null ||
        _pacienteSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    final frecuencia = int.tryParse(_frecuenciaHorasController.text);
    if (frecuencia == null || frecuencia <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Frecuencia inválida")),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_pacienteSeleccionadoId)
        .collection('medicamentos');

    if (_medicamentoIdEditando != null) {
      await docRef.doc(_medicamentoIdEditando).update({
        'medicamento': _medicamentoController.text.trim(),
        'dosis': _dosisController.text.trim(),
        'frecuenciaHoras': frecuencia,
        'fechaInicio': Timestamp.fromDate(_fechaInicio!),
        'fechaFin': Timestamp.fromDate(_fechaFin!),
      });
    } else {
      await docRef.add({
        'medicamento': _medicamentoController.text.trim(),
        'dosis': _dosisController.text.trim(),
        'frecuenciaHoras': frecuencia,
        'fechaInicio': Timestamp.fromDate(_fechaInicio!),
        'fechaFin': Timestamp.fromDate(_fechaFin!),
        'creadoEn': Timestamp.now(),
      });
    }

    _medicamentoController.clear();
    _dosisController.clear();
    _frecuenciaHorasController.clear();
    _fechaInicio = null;
    _fechaFin = null;
    _medicamentoIdEditando = null;

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicamento guardado')),
      );
    }
  }

  void _mostrarDialogoNuevoMedicamento({DocumentSnapshot? doc}) {
    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>;
      _medicamentoIdEditando = doc.id;
      _medicamentoController.text = data['medicamento'] ?? '';
      _dosisController.text = data['dosis'] ?? '';
      _frecuenciaHorasController.text = data['frecuenciaHoras'].toString();
      _fechaInicio = (data['fechaInicio'] as Timestamp).toDate();
      _fechaFin = (data['fechaFin'] as Timestamp).toDate();
    } else {
      _medicamentoIdEditando = null;
      _medicamentoController.clear();
      _dosisController.clear();
      _frecuenciaHorasController.clear();
      _fechaInicio = null;
      _fechaFin = null;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_medicamentoIdEditando != null ? 'Editar Medicamento' : 'Asignar Medicamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _medicamentoController,
              decoration: const InputDecoration(labelText: 'Nombre del medicamento'),
            ),
            TextFormField(
              controller: _dosisController,
              decoration: const InputDecoration(labelText: 'Dosis / instrucciones'),
            ),
            TextFormField(
              controller: _frecuenciaHorasController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Frecuencia (cada cuántas horas)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: _fechaInicio ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (fecha != null) setState(() => _fechaInicio = fecha);
              },
              child: const Text("Seleccionar fecha de inicio"),
            ),
            if (_fechaInicio != null)
              Text("Inicio: ${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}"),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: _fechaFin ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (fecha != null) setState(() => _fechaFin = fecha);
              },
              child: const Text("Seleccionar fecha de fin"),
            ),
            if (_fechaFin != null)
              Text("Fin: ${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(onPressed: _asignarMedicamento, child: const Text("Guardar")),
        ],
      ),
    );
  }

  Future<void> _eliminarMedicamento(String medicamentoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Medicamento'),
        content: const Text('¿Estás seguro de eliminar este medicamento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_pacienteSeleccionadoId)
          .collection('medicamentos')
          .doc(medicamentoId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicamento eliminado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan de Medicación')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      _pacienteSeleccionadoNombre = pacientes.firstWhere((doc) => doc.id == value)['name'];
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
                      .collection('medicamentos')
                      .orderBy('fechaInicio')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();
                    final medicamentos = snapshot.data!.docs;
                    if (medicamentos.isEmpty) {
                      return const Text("No hay medicamentos asignados.");
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Medicamentos de $_pacienteSeleccionadoNombre", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: medicamentos.length,
                            itemBuilder: (context, index) {
                              final doc = medicamentos[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final inicio = (data['fechaInicio'] as Timestamp).toDate();
                              final fin = (data['fechaFin'] as Timestamp).toDate();
                              return Card(
                                child: ListTile(
                                  title: Text(data['medicamento'] ?? 'Sin nombre'),
                                  subtitle: Text("${data['dosis']}\nCada ${data['frecuenciaHoras']} horas\n${inicio.day}/${inicio.month}/${inicio.year} - ${fin.day}/${fin.month}/${fin.year}"),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _mostrarDialogoNuevoMedicamento(doc: doc),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _eliminarMedicamento(doc.id),
                                      ),
                                    ],
                                  ),
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
              onPressed: () => _mostrarDialogoNuevoMedicamento(),
              label: const Text("Asignar medicamento"),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}
