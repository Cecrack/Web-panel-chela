import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Para formatear fechas

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  // Campos para la creación de una nueva cita por el médico
  String? _pacienteSeleccionadoId;
  String? _pacienteSeleccionadoNombre;
  final TextEditingController _motivoController = TextEditingController();
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  String? _medicoUid;

  @override
  void initState() {
    super.initState();
    _loadMedicoUid();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicoUid() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _medicoUid = user.uid;
      });
    } else {
      // Considera mostrar un diálogo o redirigir si no hay usuario logueado.
      print("Error: CitasScreen cargado sin un médico logueado.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, inicia sesión para gestionar citas.')),
        );
      }
    }
  }

  // Función para crear una nueva cita (hecha por el médico)
  void _crearCita() async {
    if (_pacienteSeleccionadoId == null ||
        _motivoController.text.trim().isEmpty ||
        _fechaSeleccionada == null ||
        _horaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos de la cita')),
      );
      return;
    }

    if (_medicoUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: UID del médico no disponible. Intenta de nuevo.')),
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

    try {
      await FirebaseFirestore.instance.collection('citas').add({
        'pacienteId': _pacienteSeleccionadoId,
        'medicoId': _medicoUid,
        'motivo': _motivoController.text.trim(),
        'fecha': Timestamp.fromDate(fechaHoraCita), // Guarda la fecha y hora seleccionada
        'estado': 'aceptada', // Estado inicial al crearla el médico
        'creadoEn': Timestamp.now(),
        'creadoPorMedico': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita creada exitosamente')),
        );
        _motivoController.clear();
        setState(() {
          _fechaSeleccionada = null;
          _horaSeleccionada = null;
        });
        Navigator.pop(context); // Cierra el diálogo
      }
    } catch (e) {
      print("Error al crear cita: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la cita: $e')),
        );
      }
    }
  }

  // Función para mostrar el diálogo de nueva cita
  void _mostrarDialogoNuevaCita() {
    // Restablecer los campos del diálogo antes de mostrarlo
    _motivoController.clear();
    _fechaSeleccionada = null;
    _horaSeleccionada = null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text('Nueva cita para ${_pacienteSeleccionadoNombre ?? "Paciente"}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _motivoController,
                    decoration: const InputDecoration(
                      labelText: 'Motivo de la cita',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    title: Text(
                      _fechaSeleccionada == null
                          ? 'Seleccionar Fecha'
                          : 'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final seleccionada = await showDatePicker(
                        context: context,
                        initialDate: _fechaSeleccionada ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)), // Permite un año atrás
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)), // 5 años en el futuro
                      );
                      if (seleccionada != null) {
                        setState(() => _fechaSeleccionada = seleccionada);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    title: Text(
                      _horaSeleccionada == null
                          ? 'Seleccionar Hora'
                          : 'Hora: ${_horaSeleccionada!.format(context)}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final seleccionada = await showTimePicker(
                        context: context,
                        initialTime: _horaSeleccionada ?? TimeOfDay.now(),
                      );
                      if (seleccionada != null) {
                        setState(() => _horaSeleccionada = seleccionada);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _crearCita,
                child: const Text('Guardar Cita'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Función para determinar el color del estado de la cita
  Color _estadoColor(String estado) {
    switch (estado) {
      case 'solicitada':
        return Colors.blueAccent; // Cita solicitada por paciente, esperando asignación
      case 'pendiente':
        return Colors.orange; // Cita que está en proceso, o esperando info
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
      await FirebaseFirestore.instance.collection('citas').doc(citaId).update({'estado': nuevoEstado});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cita marcada como $nuevoEstado')),
        );
      }
    } catch (e) {
      print("Error al actualizar estado de cita: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el estado: $e')),
        );
      }
    }
  }

  // Función para asignar una cita solicitada al médico actual
  Future<void> _asignarCita(String citaId) async {
    if (_medicoUid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No se pudo obtener el ID del médico.')),
        );
      }
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('citas').doc(citaId).update({
        'medicoId': _medicoUid,
        'estado': 'aceptada', // Estado inicial después de la asignación
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita asignada y aceptada.')),
        );
      }
    } catch (e) {
      print("Error al asignar cita: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al asignar la cita: $e')),
        );
      }
    }
  }

  // NUEVA FUNCIÓN: Eliminar Cita
  Future<void> _eliminarCita(String citaId) async {
    // Preguntar confirmación antes de eliminar
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta cita? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance.collection('citas').doc(citaId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cita eliminada exitosamente.')),
          );
        }
      } catch (e) {
        print("Error al eliminar cita: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar la cita: $e')),
          );
        }
      }
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Citas Médicas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mis Citas', icon: Icon(Icons.calendar_today)),
              Tab(text: 'Solicitudes', icon: Icon(Icons.inbox)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyCitasTab(), // Pestaña de Mis Citas
            _buildRequestedCitasTab(), // Pestaña de Solicitudes
          ],
        ),
        floatingActionButton: _pacienteSeleccionadoId != null
            ? FloatingActionButton.extended(
                onPressed: _mostrarDialogoNuevaCita,
                label: Text("Agendar para: ${_pacienteSeleccionadoNombre ?? 'Paciente'}"),
                icon: const Icon(Icons.add),
              )
            : null, // No muestra FAB si no hay paciente seleccionado
      ),
    );
  }

  // ********************************************
  // ** Widgets de las pestañas **
  // ********************************************

  Widget _buildMyCitasTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Seleccionar paciente (para crear nueva cita):",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'paciente')
                    .orderBy('name') // Asegúrate de tener el índice compuesto para 'role' y 'name'
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
                        _pacienteSeleccionadoNombre = pacientes
                            .firstWhere((doc) => doc.id == value)['name'] as String?;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "Mis Citas Asignadas:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
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
                return const Center(
                    child: Text(
                  "No tienes citas asignadas o creadas por ti.",
                  textAlign: TextAlign.center,
                ));
              }

              return ListView.builder(
                itemCount: citas.length,
                itemBuilder: (context, index) {
                  final doc = citas[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _CitaCard(
                    citaData: data,
                    citaId: doc.id,
                    onUpdateStatus: _actualizarEstadoCita,
                    onDeleteCita: _eliminarCita, // PASAR LA FUNCIÓN DE ELIMINAR
                    estadoColor: _estadoColor(data['estado'] ?? 'pendiente'),
                    showAssignButton: false, // No mostrar botón de asignar en 'Mis Citas'
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestedCitasTab() {
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
              stream: FirebaseFirestore.instance
                  .collection('citas')
                  .where('estado', isEqualTo: 'solicitada')
                  .where('medicoId', isNull: true) // Asegura que aún no tiene médico asignado
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
                    return _CitaCard(
                      citaData: data,
                      citaId: doc.id,
                      onAssignCita: _asignarCita,
                      estadoColor: _estadoColor(data['estado'] ?? 'solicitada'),
                      showAssignButton: true, // Mostrar botón de asignar
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

// ********************************************
// ** Widget Separado para la Tarjeta de Cita **
// ********************************************

class _CitaCard extends StatelessWidget {
  final Map<String, dynamic> citaData;
  final String citaId;
  final Function(String, String)? onUpdateStatus; // Para Mis Citas (cambiar estado)
  final Function(String)? onAssignCita; // Para Solicitudes (asignar)
  final Function(String)? onDeleteCita; // NUEVO: Para Mis Citas (eliminar)
  final Color estadoColor;
  final bool showAssignButton;

  const _CitaCard({
    required this.citaData,
    required this.citaId,
    this.onUpdateStatus,
    this.onAssignCita,
    this.onDeleteCita, // Nuevo parámetro
    required this.estadoColor,
    this.showAssignButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime fecha = (citaData['fecha'] as Timestamp).toDate();
    final String motivo = citaData['motivo'] as String? ?? 'Sin motivo especificado';
    final String estado = citaData['estado'] as String? ?? 'desconocido';
    final String pacienteId = citaData['pacienteId'] as String;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(pacienteId).get(),
                  builder: (context, pacienteSnapshot) {
                    String pacienteNombre = 'Cargando paciente...';
                    if (pacienteSnapshot.connectionState == ConnectionState.waiting) {
                      pacienteNombre = 'Cargando...';
                    } else if (pacienteSnapshot.hasData && pacienteSnapshot.data!.exists) {
                      pacienteNombre = pacienteSnapshot.data!['name'] as String? ?? 'Paciente Desconocido';
                    } else if (pacienteSnapshot.hasError) {
                      pacienteNombre = 'Error al cargar paciente';
                    } else {
                      pacienteNombre = 'Paciente no encontrado';
                    }
                    return Flexible(
                      child: Text(
                        'Paciente: $pacienteNombre',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    estado.toUpperCase(),
                    style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Motivo: $motivo',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Fecha: ${DateFormat('dd/MM/yyyy - HH:mm').format(fecha)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showAssignButton)
                  ElevatedButton.icon(
                    onPressed: onAssignCita != null ? () => onAssignCita!(citaId) : null,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Asignar a mí'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  )
                else // Si no es una solicitud, mostrar el menú de opciones
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'delete' && onDeleteCita != null) {
                        onDeleteCita!(citaId);
                      } else if (onUpdateStatus != null) {
                        onUpdateStatus!(citaId, action);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'pendiente', child: Text('Marcar Pendiente')),
                      const PopupMenuItem(value: 'aceptada', child: Text('Marcar Aceptada')),
                      const PopupMenuItem(value: 'rechazada', child: Text('Marcar Rechazada')),
                      const PopupMenuItem(value: 'completada', child: Text('Marcar Completada')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar Cita', style: TextStyle(color: Colors.red)),
                      ), // Opción de eliminar
                    ],
                    child: Chip(
                      label: const Text('Opciones', style: TextStyle(color: Colors.white)),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      avatar: const Icon(Icons.more_vert, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}