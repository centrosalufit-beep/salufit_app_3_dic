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
    // CORRECCIÓN: Quitamos 'locale' para evitar el error si no hay localizaciones configuradas
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      // locale: const Locale('es', 'ES'), // <--- LÍNEA BORRADA PARA EVITAR EL CRASH
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

  Future<void> _generarPDF() async {
    setState(() { _isLoading = true; });

    try {
      // 1. PREPARAR FECHAS
      DateTime start = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
      DateTime end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      // 2. CONSULTA A FIREBASE (Usamos DateTime directo, Flutter lo convierte a Timestamp solo)
      var querySnapshot = await FirebaseFirestore.instance
          .collection('timeClockRecords')
          .where('timestamp', isGreaterThanOrEqualTo: start) // <--- CAMBIO: Pasamos DateTime directo
          .where('timestamp', isLessThanOrEqualTo: end)      // <--- CAMBIO: Pasamos DateTime directo
          .orderBy('timestamp', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay fichajes en esas fechas")));
        setState(() { _isLoading = false; });
        return;
      }

      // 3. OBTENER NOMBRES
      Set<String> userIds = querySnapshot.docs.map((d) => d['userId'] as String).toSet();
      Map<String, String> userNames = {};

      List<String> idsList = userIds.toList();
      for (var i = 0; i < idsList.length; i += 10) {
        var endChunk = (i + 10 < idsList.length) ? i + 10 : idsList.length;
        var chunk = idsList.sublist(i, endChunk);
        
        var usersSnap = await FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: chunk).get();
        for (var doc in usersSnap.docs) {
          var data = doc.data();
          userNames[doc.id] = data['nombreCompleto'] ?? data['nombre'] ?? "Usuario ${doc.id}";
        }
      }

      // 4. CONSTRUIR PDF
      final pdf = pw.Document();
      final headers = ['Fecha', 'Hora', 'Tipo', 'Empleado', 'ID', 'Incidencia'];
      
      final data = querySnapshot.docs.map((doc) {
        Map<String, dynamic> map = doc.data();
        DateTime dt = (map['timestamp'] as Timestamp).toDate();
        
        String tipo = map['type'] == 'IN' ? 'ENTRADA' : 'SALIDA';
        String nombre = userNames[map['userId']] ?? "ID: ${map['userId']}";
        bool manual = map['isManualEntry'] ?? false;
        
        return [
          DateFormat('dd/MM/yyyy').format(dt),
          DateFormat('HH:mm').format(dt),
          tipo,
          nombre,
          map['userId'],
          manual ? "MANUAL" : ""
        ];
      }).toList();

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
                    pw.Text('Generado: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  ]
                )
              ),
              pw.SizedBox(height: 20),
              pw.Text("Periodo: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}", style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),
              
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: data,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                cellStyle: const pw.TextStyle(fontSize: 9),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                }
              ),
            ];
          },
        ),
      );

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'registro_jornada.pdf');

    } catch (e) {
      print("ERROR PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(title: const Text("Informes de Jornada"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Selecciona el rango:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: _DateCard(label: "Desde", date: _startDate),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: _DateCard(label: "Hasta", date: _endDate),
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
                label: const Text("DESCARGAR INFORME PDF"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            const Text(
              "Este informe cumple con la normativa de registro horario (Art 34.9 ET). Incluye hora, tipo de fichaje y correcciones manuales.",
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