import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminTimeReportScreen extends StatefulWidget {
  const AdminTimeReportScreen({super.key});

  @override
  State<AdminTimeReportScreen> createState() => _AdminTimeReportScreenState();
}

class _AdminTimeReportScreenState extends State<AdminTimeReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30)); 
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        } else {
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  // Función auxiliar para formatear duración (ej: 4h 30m)
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    return '${twoDigits(d.inHours)}:$twoDigitMinutes h';
  }

  Future<void> _generarPDF() async {
    setState(() { _isLoading = true; });

    try {
      // 1. PREPARAR FECHAS
      final DateTime start = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
      final DateTime end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      // 2. CONSULTA A FIREBASE
      final querySnapshot = await FirebaseFirestore.instance
          .collection('timeClockRecords')
          .where('timestamp', isGreaterThanOrEqualTo: start)
          .where('timestamp', isLessThanOrEqualTo: end)
          .orderBy('timestamp', descending: false) // Importante: Ascendente para emparejar IN -> OUT
          .get();

      // CORRECCIÓN: Check mounted antes de usar context
      if (!mounted) return;

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay fichajes en esas fechas')));
        setState(() { _isLoading = false; });
        return;
      }

      // 3. OBTENER NOMBRES
      final Set<String> userIds = querySnapshot.docs.map((d) => d['userId'] as String).toSet();
      final Map<String, String> userNames = {};

      final List<String> idsList = userIds.toList();
      for (var i = 0; i < idsList.length; i += 10) {
        final endChunk = (i + 10 < idsList.length) ? i + 10 : idsList.length;
        final chunk = idsList.sublist(i, endChunk);
        
        final usersSnap = await FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: chunk).get();
        for (var doc in usersSnap.docs) {
          final data = doc.data();
          userNames[doc.id] = data['nombreCompleto'] ?? data['nombre'] ?? 'Usuario ${doc.id}';
        }
      }

      // 4. PROCESAR DATOS: AGRUPAR ENTRADAS Y SALIDAS (LA LÓGICA CLAVE)
      final Map<String, List<QueryDocumentSnapshot>> recordsByUser = {};
      for (var doc in querySnapshot.docs) {
        final String uid = doc['userId'];
        if (!recordsByUser.containsKey(uid)) recordsByUser[uid] = [];
        recordsByUser[uid]!.add(doc);
      }

      final List<List<String>> tableData = [];

      // Recorremos usuario por usuario para armar sus jornadas
      recordsByUser.forEach((uid, records) {
        final String nombreEmpleado = userNames[uid] ?? 'ID: $uid';
        
        // Variables temporales para buscar parejas IN -> OUT
        DateTime? entryTime;
        bool isManualEntry = false;

        for (var record in records) {
          final Map<String, dynamic> data = record.data() as Map<String, dynamic>;
          final DateTime time = (data['timestamp'] as Timestamp).toDate();
          final String type = data['type']; // 'IN' o 'OUT'
          final bool manual = data['isManualEntry'] ?? false;

          if (type == 'IN') {
            // Si ya teníamos una entrada abierta sin cerrar, la cerramos como error
            if (entryTime != null) {
              tableData.add([
                DateFormat('dd/MM/yyyy').format(entryTime),
                nombreEmpleado,
                DateFormat('HH:mm').format(entryTime),
                'SIN SALIDA',
                '---',
                'Error: Fichaje abierto'
              ]);
            }
            // Abrimos nueva sesión
            entryTime = time;
            isManualEntry = manual;
          } else if (type == 'OUT') {
            if (entryTime != null) {
              // ¡Tenemos pareja! Cerrar sesión
              final Duration duration = time.difference(entryTime);
              final bool manualExit = manual;
              
              // Verificamos si la salida es el mismo día o día siguiente
              final String fechaStr = DateFormat('dd/MM/yyyy').format(entryTime);
              
              tableData.add([
                fechaStr,
                nombreEmpleado,
                DateFormat('HH:mm').format(entryTime),
                DateFormat('HH:mm').format(time),
                _formatDuration(duration),
                (isManualEntry || manualExit) ? 'CORRECCIÓN MANUAL' : ''
              ]);

              entryTime = null; // Reset para siguiente ciclo
              isManualEntry = false;
            } else {
              // Salida huérfana (sin entrada)
              tableData.add([
                DateFormat('dd/MM/yyyy').format(time),
                nombreEmpleado,
                '---',
                DateFormat('HH:mm').format(time),
                '---',
                'Error: Falta entrada'
              ]);
            }
          }
        }

        // Si al acabar el bucle queda una entrada abierta
        if (entryTime != null) {
          tableData.add([
            DateFormat('dd/MM/yyyy').format(entryTime),
            nombreEmpleado,
            DateFormat('HH:mm').format(entryTime),
            'EN CURSO',
            '---',
            'Jornada activa'
          ]);
        }
      });

      // Ordenamos la tabla final por fecha
      tableData.sort((a, b) {
        // Formato dd/MM/yyyy -> convertir para ordenar
        try {
          final DateTime dateA = DateFormat('dd/MM/yyyy').parse(a[0]);
          final DateTime dateB = DateFormat('dd/MM/yyyy').parse(b[0]);
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });

      // 5. GENERAR PDF
      final pdf = pw.Document();
      final headers = ['Fecha', 'Empleado', 'Entrada', 'Salida', 'Duración', 'Notas'];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Registro de Jornada - SALUFIT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  ]
                )
              ),
              pw.SizedBox(height: 20),
              pw.Text("Periodo: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}", style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),
              
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: tableData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                cellStyle: const pw.TextStyle(fontSize: 9),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.center, // Fecha
                  2: pw.Alignment.center, // Entrada
                  3: pw.Alignment.center, // Salida
                  4: pw.Alignment.centerRight, // Duración
                }
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 20),
                child: pw.Text(
                  "* El cálculo de duración se realiza automáticamente entre fichaje de entrada y salida. Las filas marcadas como 'MANUAL' indican que la hora fue corregida por el empleado o sistema.",
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)
                )
              )
            ];
          },
        ),
      );

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'informe_jornada_detallado.pdf');

    } catch (e) {
      debugPrint('ERROR PDF: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(title: const Text('Informes de Jornada'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona el rango:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: _DateCard(label: 'Desde', date: _startDate),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: _DateCard(label: 'Hasta', date: _endDate),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generarPDF,
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.picture_as_pdf),
                label: const Text('DESCARGAR INFORME DETALLADO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            const Text(
              'El informe agrupa automáticamente las entradas y salidas para calcular las horas trabajadas por sesión.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final DateTime date;
  const _DateCard({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.teal),
              const SizedBox(width: 8),
              Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }
}