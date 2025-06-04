// lib/screens/medicamentos_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Importar para formatear fechas

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

  @override
  void dispose() {
    _medicamentoController.dispose();
    _dosisController.dispose();
    _frecuenciaHorasController.dispose();
    super.dispose();
  }

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

    try {
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

      // Limpiar campos después de guardar
      _medicamentoController.clear();
      _dosisController.clear();
      _frecuenciaHorasController.clear();
      _fechaInicio = null;
      _fechaFin = null;
      _medicamentoIdEditando = null;

      if (mounted) {
        Navigator.pop(context); // Cierra el diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicamento guardado')),
        );
      }
    } catch (e) {
      print("Error al guardar medicamento: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar medicamento: $e')),
        );
      }
    }
  }

  void _mostrarDialogoNuevoMedicamento({DocumentSnapshot? doc}) {
    // Asegurarse de que los controladores y fechas reflejen los datos del documento si se está editando
    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>;
      _medicamentoIdEditando = doc.id;
      _medicamentoController.text = data['medicamento'] ?? '';
      _dosisController.text = data['dosis'] ?? '';
      _frecuenciaHorasController.text = data['frecuenciaHoras']?.toString() ?? '';
      _fechaInicio = (data['fechaInicio'] as Timestamp?)?.toDate();
      _fechaFin = (data['fechaFin'] as Timestamp?)?.toDate();
    } else {
      // Si no se está editando, limpiar para un nuevo medicamento
      _medicamentoIdEditando = null;
      _medicamentoController.clear();
      _dosisController.clear();
      _frecuenciaHorasController.clear();
      _fechaInicio = null;
      _fechaFin = null;
    }

    // Usar StatefulBuilder para que el diálogo pueda reconstruirse internamente
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateSB) { // setStateSB para el diálogo
            return AlertDialog(
              title: Text(_medicamentoIdEditando != null ? 'Editar Medicamento' : 'Asignar Medicamento'),
              content: SingleChildScrollView(
                child: Column(
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
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        _fechaInicio == null
                            ? "Seleccionar fecha de inicio"
                            : "Inicio: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)}",
                      ),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: _fechaInicio ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)), // 5 años atrás
                          lastDate: DateTime.now().add(const Duration(days: 365 * 10)), // 10 años adelante
                        );
                        if (fecha != null) {
                          setStateSB(() => _fechaInicio = fecha); // Usar setStateSB para actualizar el diálogo
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: Text(
                        _fechaFin == null
                            ? "Seleccionar fecha de fin"
                            : "Fin: ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}",
                      ),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: _fechaFin ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)), // 5 años atrás
                          lastDate: DateTime.now().add(const Duration(days: 365 * 10)), // 10 años adelante
                        );
                        if (fecha != null) {
                          setStateSB(() => _fechaFin = fecha); // Usar setStateSB para actualizar el diálogo
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: _asignarMedicamento,
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red), // Color para el botón de eliminar
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (_pacienteSeleccionadoId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No hay paciente seleccionado para eliminar el medicamento.')),
          );
        }
        return;
      }
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_pacienteSeleccionadoId)
            .collection('medicamentos')
            .doc(medicamentoId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicamento eliminado')),
          );
        }
      } catch (e) {
        print("Error al eliminar medicamento: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar medicamento: $e')),
          );
        }
      }
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
            const Text("Seleccionar paciente:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'paciente')
                  .orderBy('name') // Es buena práctica ordenar para UI consistente
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar pacientes: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final pacientes = snapshot.data!.docs;
                if (pacientes.isEmpty) {
                  return const Text("No hay pacientes registrados con el rol 'paciente'.");
                }

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Paciente',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _pacienteSeleccionadoId,
                  hint: const Text("Selecciona un paciente"),
                  isExpanded: true,
                  items: pacientes.map((doc) {
                    final nombre = doc['name'] as String? ?? 'Nombre Desconocido';
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(nombre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _pacienteSeleccionadoId = value;
                      _pacienteSeleccionadoNombre =
                          pacientes.firstWhere((doc) => doc.id == value)['name'] as String?;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            if (_pacienteSeleccionadoId != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Medicamentos de ${_pacienteSeleccionadoNombre ?? 'Paciente'}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(_pacienteSeleccionadoId)
                            .collection('medicamentos')
                            .orderBy('fechaInicio')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text('Error al cargar medicamentos: ${snapshot.error}'));
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final medicamentos = snapshot.data!.docs;
                          if (medicamentos.isEmpty) {
                            return Center(
                                child: Text("No hay medicamentos asignados a ${_pacienteSeleccionadoNombre ?? 'este paciente'}."));
                          }
                          return ListView.builder(
                            itemCount: medicamentos.length,
                            itemBuilder: (context, index) {
                              final doc = medicamentos[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final inicio = (data['fechaInicio'] as Timestamp).toDate();
                              final fin = (data['fechaFin'] as Timestamp).toDate();
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                elevation: 2,
                                child: ListTile(
                                  title: Text(data['medicamento'] ?? 'Sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    "${data['dosis']}\n"
                                    "Cada ${data['frecuenciaHoras']} horas\n"
                                    "Periodo: ${DateFormat('dd/MM/yyyy').format(inicio)} - ${DateFormat('dd/MM/yyyy').format(fin)}",
                                  ),
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
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            else
              const Center(child: Text("Selecciona un paciente para ver o asignar medicamentos.")),
          ],
        ),
      ),
      floatingActionButton: _pacienteSeleccionadoId != null
          ? FloatingActionButton.extended(
              onPressed: () => _mostrarDialogoNuevoMedicamento(),
              label: Text("Asignar medicamento a ${_pacienteSeleccionadoNombre ?? 'Paciente'}"),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}