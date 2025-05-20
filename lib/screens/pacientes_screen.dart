import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CumplimientoResumen extends StatelessWidget {
  final String medicamento;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int tomasPrevistas;
  final int tomasRealizadas;

  const CumplimientoResumen({
    super.key,
    required this.medicamento,
    required this.fechaInicio,
    required this.fechaFin,
    required this.tomasPrevistas,
    required this.tomasRealizadas,
  });

  @override
  Widget build(BuildContext context) {
    final duracionDias = fechaFin.difference(fechaInicio).inDays + 1;
    final porcentaje = tomasPrevistas > 0
        ? tomasRealizadas / tomasPrevistas
        : 0.0;

    Color getColor() {
      if (porcentaje >= 0.9) return Colors.green;
      if (porcentaje >= 0.7) return Colors.orange;
      return Colors.red;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medication, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    medicamento,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Duración: $duracionDias días (del ${fechaInicio.day}/${fechaInicio.month} al ${fechaFin.day}/${fechaFin.month})'),
            Text('Tomas previstas: $tomasPrevistas'),
            Text('Tomas realizadas: $tomasRealizadas'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: porcentaje,
              minHeight: 10,
              color: getColor(),
              backgroundColor: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('${(porcentaje * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(Icons.circle, color: getColor(), size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class PacientesScreen extends StatefulWidget {
  const PacientesScreen({super.key});

  @override
  State<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> with TickerProviderStateMixin {
  String? _pacienteSeleccionadoId;
  String? _pacienteSeleccionadoNombre;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Paciente"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Signos Vitales"),
              Tab(text: "Cumplimiento"),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text("Seleccionar paciente:", style: TextStyle(fontWeight: FontWeight.bold)),
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
              Expanded(
                child: _pacienteSeleccionadoId == null
                    ? const Center(child: Text("Selecciona un paciente para ver la información"))
                    : TabBarView(
                        children: [
                          // Pestaña signos vitales
                          Column(
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (_pacienteSeleccionadoId != null && _pacienteSeleccionadoNombre != null) {
                                      generarReporteSignosVitales(
                                        pacienteId: _pacienteSeleccionadoId!,
                                        pacienteNombre: _pacienteSeleccionadoNombre!,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text("Descargar PDF"),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(_pacienteSeleccionadoId)
                                      .collection('signosVitales')
                                      .orderBy('fecha', descending: true)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    final signos = snapshot.data!.docs;
                                    if (signos.isEmpty) {
                                      return const Center(child: Text("Este paciente no tiene registros."));
                                    }
                                    return ListView.builder(
                                      itemCount: signos.length,
                                      itemBuilder: (context, index) {
                                        final data = signos[index].data() as Map<String, dynamic>;
                                        final fecha = (data['fecha'] as Timestamp).toDate();
                                        return Card(
                                          margin: const EdgeInsets.symmetric(vertical: 6),
                                          child: ListTile(
                                            title: Text("Presión: ${data['presion']}, Temp: ${data['temperatura']} °C"),
                                            subtitle: Text(
                                              "Frecuencia: ${data['frecuenciaCardiaca']} lpm\nFecha: ${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}",
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

                          // Pestaña cumplimiento actualizada con barras visuales
                          Column(
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (_pacienteSeleccionadoId != null && _pacienteSeleccionadoNombre != null) {
                                      generarReporteCumplimiento(
                                        pacienteId: _pacienteSeleccionadoId!,
                                        pacienteNombre: _pacienteSeleccionadoNombre!,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text("Descargar Cumplimiento"),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(_pacienteSeleccionadoId)
                                      .collection('medicamentos')
                                      .get(),
                                  builder: (context, medsSnapshot) {
                                    if (!medsSnapshot.hasData) return const CircularProgressIndicator();
                                    final medicamentos = medsSnapshot.data!.docs;

                                    return StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(_pacienteSeleccionadoId)
                                          .collection('tomas')
                                          .orderBy('fecha', descending: true)
                                          .snapshots(),
                                      builder: (context, tomasSnapshot) {
                                        if (!tomasSnapshot.hasData) return const CircularProgressIndicator();
                                        final tomas = tomasSnapshot.data!.docs;

                                        if (medicamentos.isEmpty) {
                                          return const Center(child: Text("No hay medicamentos asignados."));
                                        }

                                        return ListView(
                                          children: medicamentos.map((medDoc) {
                                            final medData = medDoc.data() as Map<String, dynamic>;
                                            final nombre = medData['medicamento'] ?? 'Desconocido';
                                            final fechaInicio = (medData['fechaInicio'] as Timestamp).toDate();
                                            final fechaFin = (medData['fechaFin'] as Timestamp).toDate();
                                            final frecuenciaHoras = medData['frecuenciaHoras'] ?? 8;
                                            final duracionDias = fechaFin.difference(fechaInicio).inDays + 1;
                                            final tomasPrevistas = ((24 / frecuenciaHoras) * duracionDias).round();

                                            final tomadas = tomas.where((doc) {
                                              final data = doc.data() as Map<String, dynamic>;
                                              return data['medicamento'] == nombre && data['tomado'] == true;
                                            }).length;

                                            return CumplimientoResumen(
                                              medicamento: nombre,
                                              fechaInicio: fechaInicio,
                                              fechaFin: fechaFin,
                                              tomasPrevistas: tomasPrevistas,
                                              tomasRealizadas: tomadas,
                                            );
                                          }).toList(),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Recuerda tener aquí las funciones generarReporteCumplimiento y generarReporteSignosVitales tal cual las tenías.rfr
Future<void> generarReporteCumplimiento({
  required String pacienteId,
  required String pacienteNombre,
}) async {
  final pdf = pw.Document();

  final medicamentosSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(pacienteId)
      .collection('medicamentos')
      .get();

  final tomasSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(pacienteId)
      .collection('tomas')
      .get();

  final medicamentos = medicamentosSnapshot.docs;
  final tomas = tomasSnapshot.docs;

  String barraProgreso(double porcentaje) {
    const int totalBloques = 20;
    int llenos = (porcentaje * totalBloques).round();
    int vacios = totalBloques - llenos;
    return '█' * llenos + '░' * vacios;
  }

  PdfColor colorPorcentaje(double porcentaje) {
    if (porcentaje >= 0.9) return PdfColors.green;
    if (porcentaje >= 0.7) return PdfColors.orange;
    return PdfColors.red;
  }

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Header(level: 0, child: pw.Text('Reporte de Cumplimiento de Medicación')),
        pw.Text('Paciente: $pacienteNombre'),
        pw.SizedBox(height: 10),
        ...medicamentos.map((medDoc) {
          final medData = medDoc.data();
          final nombre = medData['medicamento'] ?? 'Desconocido';
          final fechaInicio = (medData['fechaInicio'] as Timestamp).toDate();
          final fechaFin = (medData['fechaFin'] as Timestamp).toDate();
          final frecuenciaHoras = medData['frecuenciaHoras'] ?? 8;

          final duracionDias = fechaFin.difference(fechaInicio).inDays + 1;
          final tomasPrevistas = ((24 / frecuenciaHoras) * duracionDias).round();

          final tomadas = tomas.where((doc) {
            final data = doc.data();
            return data['medicamento'] == nombre && data['tomado'] == true;
          }).length;

          final porcentaje = tomasPrevistas > 0 ? tomadas / tomasPrevistas : 0.0;
          final porcentajeStr = (porcentaje * 100).toStringAsFixed(1);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Medicamento: $nombre', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Duración: $duracionDias días (del ${fechaInicio.day}/${fechaInicio.month} al ${fechaFin.day}/${fechaFin.month})'),
              pw.Text('Tomas previstas: $tomasPrevistas'),
              pw.Text('Tomas realizadas: $tomadas'),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'Cumplimiento: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(
                      text: barraProgreso(porcentaje) + ' ',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: colorPorcentaje(porcentaje),
                      ),
                    ),
                    pw.TextSpan(text: '($porcentajeStr%)  '),
                    pw.TextSpan(
                      text: porcentaje >= 0.9
                          ? '🟢'
                          : porcentaje >= 0.7
                              ? '🟠'
                              : '🔴',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
            ],
          );
        }).toList(),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
}

// función de PDF de signos vitales o más funciones pueden ir aquí abajo
Future<void> generarReporteSignosVitales({
  required String pacienteId,
  required String pacienteNombre,
}) async {
  final pdf = pw.Document();

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(pacienteId)
      .collection('signosVitales')
      .orderBy('fecha', descending: true)
      .get();

  final registros = snapshot.docs;

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Header(level: 0, child: pw.Text('Reporte de Signos Vitales')),
        pw.Text('Paciente: $pacienteNombre'),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: ['Fecha', 'Temperatura (°C)', 'Presión', 'Frecuencia (lpm)'],
          data: registros.map((doc) {
            final data = doc.data();
            final fecha = (data['fecha'] as Timestamp).toDate();
            return [
              '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
              data['temperatura'].toString(),
              data['presion'].toString(),
              data['frecuenciaCardiaca'].toString(),
            ];
          }).toList(),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
}
