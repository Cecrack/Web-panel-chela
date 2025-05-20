import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Para formatear fechas

class CitasScreen extends StatefulWidget {
  // Las notifications ya no serían necesarias aquí, se manejan aparte si las quieres mostrar.
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  // Los campos de pacienteSeleccionado son para cuando el médico crea una cita
  String? _pacienteSeleccionadoId;
  String? _pacienteSeleccionadoNombre;
  final _motivoController = TextEditingController();
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  String? _medicoUid;

  // Los ScrollControllers y variables de paginación serían necesarios si usaras paginación para ambas listas.
  // Para simplificar aquí, vamos a usar StreamBuilder sin paginación inicialmente para las solicitudes.
  // Si necesitas paginación en ambas, duplica la lógica _loadMoreCitas para cada tipo de stream.

  @override
  void initState() {
    super.initState();
    _loadMedicoUid();
    // No necesitamos _scrollController.addListener aquí si usamos StreamBuilder para cada lista
  }

  @override
  void dispose() {
    _motivoController.dispose();
    // Si tienes scroll controllers específicos para cada lista, deséchalos aquí.
    super.dispose();
  }

  Future<void> _loadMedicoUid() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _medicoUid = user.uid;
      });
      // No llamar _loadMoreCitas aquí, los StreamBuilders lo harán
    } else {
      print("Error: CitasScreen cargado sin un médico logueado.");
      // Podrías redirigir al login o mostrar un mensaje.
    }
  }

  // Función para crear una nueva cita (hecha por el médico)
  void _crearCita() async {
    if (_pacienteSeleccionadoId == null ||
        _motivoController.text.isEmpty ||
        _fechaSeleccionada == null ||
        _horaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    if (_medicoUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: UID del médico no disponible')),
      );
      return;
    }

    final fechaHoraCita = DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      _horaSeleccionada!.hour,
      _horaSeleccionada!.minute,
    );

    final fechaHoraLocal = fechaHoraCita.toLocal();

    try {
      await FirebaseFirestore.instance.collection('citas').add({
        'pacienteId': _pacienteSeleccionadoId,
        'medicoId': _medicoUid, // Asignada al médico que la crea
        'motivo': _motivoController.text.trim(),
        'fecha': Timestamp.fromDate(fechaHoraLocal),
        'estado': 'aceptada', // O 'confirmada', 'pendiente', tú decides el estado inicial
        'creadoEn': Timestamp.now(),
        'creadoPorMedico': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita creada exitosamente')),
      );

      _motivoController.clear();
      _fechaSeleccionada = null;
      _horaSeleccionada = null;
      Navigator.pop(context); // Cierra el diálogo
    } catch (e) {
      print("Error al crear cita: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear la cita: $e')),
      );
    }
  }

  // Función para mostrar el diálogo de nueva cita
  void _mostrarDialogoNuevaCita() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nueva cita para ${_pacienteSeleccionadoNombre ?? "Paciente"}'),
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
              Text("Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)}"),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final seleccionada = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (seleccionada != null) {
                  setState(() => _horaSeleccionada = seleccionada);
                }
              },
              child: const Text('Seleccionar hora'),
            ),
            if (_horaSeleccionada != null)
              Text("Hora: ${_horaSeleccionada!.format(context)}"),
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

  // Función para determinar el color del estado de la cita
  Color _estadoColor(String estado) {
    switch (estado) {
      case 'solicitada': // Cita solicitada por paciente, esperando asignación
        return Colors.blueAccent;
      case 'pendiente': // Cita que está en proceso, o esperando info
        return Colors.orange;
      case 'aceptada':
        return Colors.green;
      case 'rechazada':
        return Colors.red;
      case 'completada':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Función para actualizar el estado de la cita
  Future<void> _actualizarEstadoCita(String citaId, String nuevoEstado) async {
    try {
      await FirebaseFirestore.instance
          .collection('citas')
          .doc(citaId)
          .update({'estado': nuevoEstado});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cita ${nuevoEstado}a')),
      );
      // No necesitas setState para _citas aquí si usas StreamBuilder,
      // el StreamBuilder se reconstruirá automáticamente con el cambio en Firestore.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el estado: $e')),
      );
    }
  }

  // Función para asignar una cita solicitada al médico actual
  Future<void> _asignarCita(String citaId) async {
    if (_medicoUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener el ID del médico.')),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('citas').doc(citaId).update({
        'medicoId': _medicoUid,
        'estado': 'aceptada', // O el estado inicial que desees después de la asignación
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita asignada y aceptada.')),
      );
    } catch (e) {
      print("Error al asignar cita: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al asignar la cita: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_medicoUid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Citas Médicas')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController( // Envuelve con DefaultTabController
      length: 2, // Número de pestañas: "Mis Citas" y "Solicitudes"
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Citas Médicas'),
          bottom: const TabBar( // Agrega TabBar al AppBar
            tabs: [
              Tab(text: 'Mis Citas', icon: Icon(Icons.calendar_today)),
              Tab(text: 'Solicitudes', icon: Icon(Icons.inbox)),
            ],
          ),
        ),
        body: TabBarView( // Contenido de las pestañas
          children: [
            // Pestaña 1: Mis Citas (Creadas por mí o asignadas a mí y aceptadas/pendientes)
            _buildMyCitasList(),
            // Pestaña 2: Solicitudes de Pacientes (estado: 'solicitada')
            _buildRequestedCitasList(),
          ],
        ),
        floatingActionButton: _pacienteSeleccionadoId != null
            ? FloatingActionButton.extended(
                onPressed: _mostrarDialogoNuevaCita,
                label: const Text("Agregar cita para paciente"),
                icon: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  // Widget para construir la lista de 'Mis Citas'
  Widget _buildMyCitasList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Seleccionar paciente (para crear nueva cita):"),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'paciente')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
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
              Text(
                "Citas asignadas a mí:",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // Consulta para citas ASIGNADAS a este médico (incluye las que él creó)
            stream: FirebaseFirestore.instance
                .collection('citas')
                .where('medicoId', isEqualTo: _medicoUid)
                .orderBy('fecha')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error al cargar mis citas: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final citas = snapshot.data!.docs;

              if (citas.isEmpty) {
                return const Center(child: Text("No tienes citas asignadas."));
              }

              return ListView.builder(
                itemCount: citas.length,
                itemBuilder: (context, index) {
                  final doc = citas[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final fecha = (data['fecha'] as Timestamp).toDate();
                  final motivo = data['motivo'] ?? 'Sin motivo';
                  final estado = data['estado'] ?? 'pendiente';
                  final estadoColor = _estadoColor(estado);
                  final pacienteIdDeCita = data['pacienteId'];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(pacienteIdDeCita)
                          .get(),
                      builder: (context, pacienteSnapshot) {
                        String pacienteNombre = 'Cargando...';
                        if (pacienteSnapshot.hasData && pacienteSnapshot.data!.exists) {
                          pacienteNombre = pacienteSnapshot.data!['name'] ?? 'Paciente Desconocido';
                        } else if (pacienteSnapshot.hasError) {
                          pacienteNombre = 'Error Paciente';
                        }

                        return ListTile(
                          leading: Icon(Icons.circle, color: estadoColor, size: 14),
                          title: Text('$motivo (Paciente: $pacienteNombre)'),
                          subtitle: Text(
                              "${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}\nEstado: $estado"),
                          trailing: PopupMenuButton<String>(
                            onSelected: (nuevoEstado) {
                              _actualizarEstadoCita(doc.id, nuevoEstado);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'pendiente', child: Text('Marcar Pendiente')),
                              const PopupMenuItem(value: 'aceptada', child: Text('Marcar Aceptada')),
                              const PopupMenuItem(value: 'rechazada', child: Text('Marcar Rechazada')),
                              const PopupMenuItem(value: 'completada', child: Text('Marcar Completada')),
                            ],
                            child: Text(estado, style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget para construir la lista de 'Solicitudes de Pacientes'
  Widget _buildRequestedCitasList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Solicitudes de Cita de Pacientes:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Consulta para citas SOLICITADAS por pacientes (medicoId es null o no existe, y estado es 'solicitada')
              stream: FirebaseFirestore.instance
                  .collection('citas')
                  .where('estado', isEqualTo: 'solicitada')
                  // Opcional: También puedes añadir .where('medicoId', isNull: true) para mayor especificidad
                  .orderBy('fecha')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar solicitudes: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final citas = snapshot.data!.docs;

                if (citas.isEmpty) {
                  return const Center(child: Text("No hay nuevas solicitudes de cita."));
                }

                return ListView.builder(
                  itemCount: citas.length,
                  itemBuilder: (context, index) {
                    final doc = citas[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final fecha = (data['fecha'] as Timestamp).toDate();
                    final motivo = data['motivo'] ?? 'Sin motivo';
                    final estado = data['estado'] ?? 'solicitada'; // Siempre 'solicitada' aquí
                    final pacienteIdDeCita = data['pacienteId'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(pacienteIdDeCita)
                            .get(),
                        builder: (context, pacienteSnapshot) {
                          String pacienteNombre = 'Cargando...';
                          if (pacienteSnapshot.hasData && pacienteSnapshot.data!.exists) {
                            pacienteNombre = pacienteSnapshot.data!['name'] ?? 'Paciente Desconocido';
                          } else if (pacienteSnapshot.hasError) {
                            pacienteNombre = 'Error Paciente';
                          }

                          return ListTile(
                            leading: Icon(Icons.circle, color: _estadoColor(estado), size: 14),
                            title: Text('$motivo (Paciente: $pacienteNombre)'),
                            subtitle: Text(
                                "${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}\nEstado: $estado"),
                            trailing: ElevatedButton(
                              onPressed: () => _asignarCita(doc.id),
                              child: const Text('Asignar a mí'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}