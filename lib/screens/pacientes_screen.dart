import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart'; // Importa Google Fonts
import 'package:intl/intl.dart'; // Para formatear fechas en la UI

// Paquetes para PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// --- Widget CumplimientoResumen (Actualizado) ---
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final duracionDias = fechaFin.difference(fechaInicio).inDays + 1;
    final porcentaje = tomasPrevistas > 0 ? tomasRealizadas / tomasPrevistas : 0.0;

    Color getColor() {
      if (porcentaje >= 0.9) return Colors.green.shade600;
      if (porcentaje >= 0.7) return Colors.orange.shade700;
      return colorScheme.error; // Usar el color de error del tema
    }

    return Card(
      elevation: 5, // Mayor elevación
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Bordes más redondeados
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0), // Quitar horizontal para que el padding del padre lo controle
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication_rounded, color: colorScheme.primary, size: 28), // Icono del tema
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    medicamento,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20), // Separador
            Text(
              'Duración: $duracionDias días (del ${DateFormat('dd/MM').format(fechaInicio)} al ${DateFormat('dd/MM').format(fechaFin)})',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            Text(
              'Tomas previstas: $tomasPrevistas',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            Text(
              'Tomas realizadas: $tomasRealizadas',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            ClipRRect( // Para redondear la barra de progreso
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: porcentaje,
                minHeight: 12, // Un poco más alta
                color: getColor(),
                backgroundColor: colorScheme.surfaceVariant, // Color de fondo del tema
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${(porcentaje * 100).toStringAsFixed(1)}%',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: getColor()),
                ),
                const SizedBox(width: 8),
                Icon(Icons.circle, color: getColor(), size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- PacientesScreen (Actualizado) ---
class PacientesScreen extends StatefulWidget {
  const PacientesScreen({super.key});

  @override
  State<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> with TickerProviderStateMixin {
  String? _pacienteSeleccionadoId;
  String? _pacienteSeleccionadoNombre;
  

  // Función para generar reporte de cumplimiento (actualizada para usar el tema)
  Future<void> generarReporteCumplimiento({
    required BuildContext context,
    required String pacienteId,
    required String pacienteNombre,
  }) async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final errorColor = Theme.of(context).colorScheme.error;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: onPrimaryColor),
            const SizedBox(width: 16),
            Text('Generando reporte de cumplimiento...', style: TextStyle(color: onPrimaryColor)),
          ],
        ),
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 30),
      ),
    );

    try {
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

      // Puedes eliminar la función barraProgreso ya que no la usaremos.
      // String barraProgreso(double porcentaje) {
      //   const int totalBloques = 20;
      //   int llenos = (porcentaje * totalBloques).round();
      //   int vacios = totalBloques - llenos;
      //   return '█' * llenos + '░' * vacios;
      // }

      PdfColor colorPorcentaje(double porcentaje) {
        if (porcentaje >= 0.9) return PdfColors.green;
        if (porcentaje >= 0.7) return PdfColors.orange;
        return PdfColors.red;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.copyWith(
            marginBottom: 1.5 * PdfPageFormat.cm,
            marginTop: 1.5 * PdfPageFormat.cm,
            marginLeft: 2.0 * PdfPageFormat.cm,
            marginRight: 2.0 * PdfPageFormat.cm,
          ),
          build: (pw.Context contextPdf) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Reporte de Cumplimiento de Medicación',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(primaryColor.value),
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Paciente: $pacienteNombre', style: pw.TextStyle(fontSize: 16)),
            pw.Text('Generado el: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 20),
            if (medicamentos.isEmpty)
              pw.Center(child: pw.Text('No hay medicamentos asignados a este paciente.', style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic)))
            else
              ...medicamentos.map((medDoc) {
                final medData = medDoc.data();
                final nombre = medData['medicamento'] ?? 'Desconocido';
                final fechaInicio = (medData['fechaInicio'] as Timestamp).toDate();
                final fechaFin = (medData['fechaFin'] as Timestamp).toDate();
                final frecuenciaHoras = medData['frecuenciaHoras'] ?? 8;

                final duracionDias = fechaFin.difference(fechaInicio).inDays + 1;
                final hoy = DateTime.now();
                final finalPeriodoConsiderado = hoy.isBefore(fechaFin) ? hoy : fechaFin;
                final diasConsiderados = finalPeriodoConsiderado.difference(fechaInicio).inDays + 1;
                final tomasPrevistas = ((24 / frecuenciaHoras) * diasConsiderados).round().clamp(0, double.infinity).toInt();

                final tomadas = tomas.where((doc) {
                  final data = doc.data();
                  final tomaFecha = (data['fechaToma'] as Timestamp?)?.toDate();
                  return data['medicamento'] == nombre &&
                         data['tomado'] == true &&
                         tomaFecha != null &&
                         tomaFecha.isAfter(fechaInicio.subtract(const Duration(days: 1))) &&
                         tomaFecha.isBefore(hoy.add(const Duration(days: 1)));
                }).length;

                final porcentaje = tomasPrevistas > 0 ? tomadas / tomasPrevistas : 0.0;
                final porcentajeStr = (porcentaje * 100).toStringAsFixed(1);

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Medicamento: $nombre', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.Text('Duración del tratamiento: $duracionDias días (del ${DateFormat('dd/MM').format(fechaInicio)} al ${DateFormat('dd/MM').format(fechaFin)})'),
                    // pw.Text('Tomas previstas: $tomasPrevistas'), // Puedes quitar esta si quieres, ya está implícita
                    // pw.Text('Tomas realizadas: $tomadas'), // Puedes quitar esta si quieres, ya está implícita
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        pw.Text('Cumplimiento: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        // ***** CAMBIO AQUÍ *****
                        pw.Text(
                          '$tomadas / $tomasPrevistas', // Muestra "realizadas / previstas"
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            color: colorPorcentaje(porcentaje),
                          ),
                        ),
                        pw.Text(' ($porcentajeStr%) '),
                        pw.Text(
                          porcentaje >= 0.9
                              ? '🟢'
                              : porcentaje >= 0.7
                                  ? '🟠'
                                  : '🔴',
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 15),
                  ],
                );
              }).toList(),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte de cumplimiento generado con éxito.'),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar el reporte de cumplimiento: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  // Función para generar reporte de signos vitales (actualizada para usar el tema)
  Future<void> generarReporteSignosVitales({
    required BuildContext context, // Añadir context para SnackBar
    required String pacienteId,
    required String pacienteNombre,
  }) async {
     // 1. Capturar los colores del tema de Flutter ANTES de construir el PDF
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
     // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: onPrimaryColor),
            const SizedBox(width: 16),
            Text(
              'Generando reporte de signos vitales...',
              style: TextStyle(color: onPrimaryColor),
            ),
          ],
        ),
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 30),
      ),
    );

    try {
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
          pageFormat: PdfPageFormat.a4.copyWith(
            marginBottom: 1.5 * PdfPageFormat.cm,
            marginTop: 1.5 * PdfPageFormat.cm,
            marginLeft: 2.0 * PdfPageFormat.cm,
            marginRight: 2.0 * PdfPageFormat.cm,
          ),
          build: (pw.Context contextPdf) => [ // Usa contextPdf para el contexto del PDF
            pw.Header(
              level: 0,
              child: pw.Text(
                'Reporte de Signos Vitales',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  // 2. Usar primaryColor (PdfColor) que se capturó antes
                  color: PdfColor.fromInt(primaryColor.value),
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Paciente: $pacienteNombre', style: pw.TextStyle(fontSize: 16)),
            pw.Text('Generado el: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 20),
            if (registros.isEmpty)
              pw.Center(child: pw.Text('No hay registros de signos vitales para este paciente.', style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic)))
            else
              pw.Table.fromTextArray(
                headers: ['Fecha', 'Temperatura (°C)', 'Presión', 'Frecuencia (lpm)'],
                data: registros.map((doc) {
                  final data = doc.data();
                  final fecha = (data['fecha'] as Timestamp).toDate();
                  return [
                    '${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}',
                    (data['temperatura'] ?? 'N/A').toString(),
                    (data['presion'] ?? 'N/A').toString(),
                    (data['frecuenciaCardiaca'] ?? 'N/A').toString(),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(Theme.of(context).colorScheme.primary.value)),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(8),
                border: pw.TableBorder.all(color: PdfColors.grey),
              ),
          ],
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte de signos vitales generado con éxito.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar el reporte de signos vitales: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          title: Text(
            "Gestión de Pacientes", // Título más descriptivo
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: colorScheme.secondary, // Color del indicador de la pestaña
            labelColor: colorScheme.onPrimary, // Color del texto de la pestaña seleccionada
            unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7), // Color del texto de la pestaña no seleccionada
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: "Signos Vitales", icon: Icon(Icons.monitor_heart_rounded)),
              Tab(text: "Cumplimiento", icon: Icon(Icons.medication_rounded)),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0), // Aumentar padding general
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Selecciona un paciente para ver su historial:",
                style: textTheme.titleMedium?.copyWith(color: colorScheme.onBackground),
              ),
              const SizedBox(height: 15),
              // Dropdown de selección de paciente
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'paciente')
                      .orderBy('name') // Ordenar por nombre para facilitar la búsqueda
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                    }
                    if (snapshot.hasError) {
                      return Text('Error al cargar pacientes: ${snapshot.error}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.error));
                    }
                    final pacientes = snapshot.data!.docs;
                    if (pacientes.isEmpty) {
                      return Text('No hay pacientes registrados.', style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic));
                    }

                    // Asegurarse de que el paciente seleccionado siga existiendo
                    if (_pacienteSeleccionadoId != null && !pacientes.any((doc) => doc.id == _pacienteSeleccionadoId)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _pacienteSeleccionadoId = null;
                          _pacienteSeleccionadoNombre = null;
                        });
                      });
                    }

                    return DropdownButtonHideUnderline( // Ocultar la línea por defecto
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _pacienteSeleccionadoId,
                        hint: Text(
                          "Selecciona un paciente",
                          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                        ),
                        icon: Icon(Icons.arrow_drop_down_circle_rounded, color: colorScheme.primary),
                        dropdownColor: colorScheme.surface, // Color del fondo del dropdown
                        style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface), // Estilo del texto de los items
                        items: pacientes.map((doc) {
                          final nombre = doc['name'] ?? 'Paciente Desconocido';
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
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: _pacienteSeleccionadoId == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_rounded, size: 80, color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                            const SizedBox(height: 16),
                            Text(
                              "Por favor, selecciona un paciente de la lista desplegable para ver su información de salud.",
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        children: [
                          // --- Pestaña Signos Vitales ---
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (_pacienteSeleccionadoId != null && _pacienteSeleccionadoNombre != null) {
                                      generarReporteSignosVitales(
                                        context: context,
                                        pacienteId: _pacienteSeleccionadoId!,
                                        pacienteNombre: _pacienteSeleccionadoNombre!,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.download_rounded),
                                  label: Text(
                                    "Descargar Reporte de Signos Vitales",
                                    style: textTheme.labelLarge,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.secondary,
                                    foregroundColor: colorScheme.onSecondary,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(_pacienteSeleccionadoId)
                                      .collection('signosVitales')
                                      .orderBy('fecha', descending: true)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                                    }
                                    if (snapshot.hasError) {
                                      return Center(child: Text('Error: ${snapshot.error}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)));
                                    }
                                    final signos = snapshot.data!.docs;
                                    if (signos.isEmpty) {
                                      return Center(
                                        child: Text(
                                          "Este paciente no tiene registros de signos vitales.",
                                          style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
                                        ),
                                      );
                                    }
                                    return ListView.builder(
                                      itemCount: signos.length,
                                      itemBuilder: (context, index) {
                                        final data = signos[index].data() as Map<String, dynamic>;
                                        final fecha = (data['fecha'] as Timestamp).toDate();
                                        return Card(
                                          elevation: 3,
                                          margin: const EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Registro del ${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}',
                                                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                                ),
                                                const Divider(height: 15, thickness: 1),
                                                _buildSignoVitalRow(
                                                  context,
                                                  icon: Icons.thermostat,
                                                  label: "Temperatura:",
                                                  value: "${data['temperatura'] ?? 'N/A'} °C",
                                                  color: Colors.orange.shade700,
                                                  textTheme: textTheme,
                                                ),
                                                _buildSignoVitalRow(
                                                  context,
                                                  icon: Icons.bloodtype,
                                                  label: "Presión Arterial:",
                                                  value: "${data['presion'] ?? 'N/A'} mmHg",
                                                  color: Colors.blue.shade700,
                                                  textTheme: textTheme,
                                                ),
                                                _buildSignoVitalRow(
                                                  context,
                                                  icon: Icons.favorite,
                                                  label: "Frecuencia Cardíaca:",
                                                  value: "${data['frecuenciaCardiaca'] ?? 'N/A'} lpm",
                                                  color: Colors.red.shade700,
                                                  textTheme: textTheme,
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

                          // --- Pestaña Cumplimiento ---
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (_pacienteSeleccionadoId != null && _pacienteSeleccionadoNombre != null) {
                                      generarReporteCumplimiento(
                                        context: context,
                                        pacienteId: _pacienteSeleccionadoId!,
                                        pacienteNombre: _pacienteSeleccionadoNombre!,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.download_rounded),
                                  label: Text(
                                    "Descargar Reporte de Cumplimiento",
                                    style: textTheme.labelLarge,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.secondary,
                                    foregroundColor: colorScheme.onSecondary,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(_pacienteSeleccionadoId)
                                      .collection('medicamentos')
                                      .get(),
                                  builder: (context, medsSnapshot) {
                                    if (medsSnapshot.connectionState == ConnectionState.waiting) {
                                      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                                    }
                                    if (medsSnapshot.hasError) {
                                      return Center(child: Text('Error: ${medsSnapshot.error}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)));
                                    }
                                    final medicamentos = medsSnapshot.data!.docs;

                                    if (medicamentos.isEmpty) {
                                      return Center(
                                        child: Text(
                                          "Este paciente no tiene medicamentos asignados.",
                                          style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
                                        ),
                                      );
                                    }

                                    return StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(_pacienteSeleccionadoId)
                                          .collection('tomas')
                                          .snapshots(), // Escuchar cambios en tiempo real en las tomas
                                      builder: (context, tomasSnapshot) {
                                        if (tomasSnapshot.connectionState == ConnectionState.waiting) {
                                          return Center(child: CircularProgressIndicator(color: colorScheme.primary));
                                        }
                                        if (tomasSnapshot.hasError) {
                                          return Center(child: Text('Error: ${tomasSnapshot.error}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)));
                                        }
                                        final tomas = tomasSnapshot.data!.docs;

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

  // Widget auxiliar para construir cada fila de signo vital (reutilizado de SignosVitalesScreen)
  Widget _buildSignoVitalRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required TextTheme textTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}