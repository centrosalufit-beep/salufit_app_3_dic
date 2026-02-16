import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// ImportaciÃƒÂ³n de seguridad
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

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
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = DateTime(picked.year, picked.month, picked.day);
        } else {
          _endDate =
              DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  // FunciÃƒÂ³n auxiliar para formatear duraciÃƒÂ³n (ej: 4h 30m)
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    return '${twoDigits(d.inHours)}:$twoDigitMinutes h';
  }

  Future<void> _generarPDF() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. PREPARAR FECHAS
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final end =
          DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      // 2. CONSULTA A FIREBASE
      final querySnapshot = await FirebaseFirestore.instance
          .collection('timeClockRecords')
          .where('timestamp', isGreaterThanOrEqualTo: start)
          .where('timestamp', isLessThanOrEqualTo: end)
          .orderBy(
            'timestamp',
            descending: false,
          ) // Importante: Ascendente para emparejar IN -> OUT
          .get();

      if (!mounted) return;

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay fichajes en esas fechas')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 3. OBTENER NOMBRES
      // CorrecciÃƒÂ³n: Acceso seguro al userId usando safeString sobre el mapa de datos
      final userIds = querySnapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> d) {
        final data = d.data();
        return data.safeString('userId');
      }).toSet();

      final userNames = <String, String>{};

      final idsList = userIds.toList();
      // Firestore 'whereIn' soporta mÃƒÂ¡ximo 10 elementos
      for (var i = 0; i < idsList.length; i += 10) {
        final endChunk = (i + 10 < idsList.length) ? i + 10 : idsList.length;
        final chunk = idsList.sublist(i, endChunk);

        if (chunk.isNotEmpty) {
          final usersSnap = await FirebaseFirestore.instance
              .collection('users')
              .where('activado', isEqualTo: true)
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          for (final doc in usersSnap.docs) {
            final data = doc.data();
            // CorrecciÃƒÂ³n: safeString para nombres
            userNames[doc.id] = data.safeString(
              'nombreCompleto',
              defaultValue: data.safeString(
                'nombre',
                defaultValue: 'Usuario ${doc.id}',
              ),
            );
          }
        }
      }

      // 4. PROCESAR DATOS: AGRUPAR ENTRADAS Y SALIDAS (LA LÃƒâ€œGICA CLAVE)
      final recordsByUser = <String, List<QueryDocumentSnapshot>>{};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final uid = data.safeString('userId');
        if (!recordsByUser.containsKey(uid)) {
          recordsByUser[uid] = <QueryDocumentSnapshot<Object?>>[];
        }
        recordsByUser[uid]!.add(doc);
      }

      final tableData = <List<String>>[];

      // Recorremos usuario por usuario para armar sus jornadas
      recordsByUser
          .forEach((String uid, List<QueryDocumentSnapshot<Object?>> records) {
        final nombreEmpleado = userNames[uid] ?? 'ID: $uid';

        // Variables temporales para buscar parejas IN -> OUT
        DateTime? entryTime;
        var isManualEntry = false;

        for (final record in records) {
          final data = record.data()! as Map<String, dynamic>;

          // CorrecciÃƒÂ³n: safeDateTime y safeString para evitar errores de dynamic
          final time = data.safeDateTime('timestamp');
          final type = data.safeString('type'); // 'IN' o 'OUT'
          final manual = data.safeBool('isManualEntry');

          if (type == 'IN') {
            // Si ya tenÃƒÂ­amos una entrada abierta sin cerrar, la cerramos como error
            if (entryTime != null) {
              tableData.add(<String>[
                DateFormat('dd/MM/yyyy').format(entryTime),
                nombreEmpleado,
                DateFormat('HH:mm').format(entryTime),
                'SIN SALIDA',
                '---',
                'Error: Fichaje abierto',
              ]);
            }
            // Abrimos nueva sesiÃƒÂ³n
            entryTime = time;
            isManualEntry = manual;
          } else if (type == 'OUT') {
            if (entryTime != null) {
              // Ã‚Â¡Tenemos pareja! Cerrar sesiÃƒÂ³n
              final duration = time.difference(entryTime);
              final manualExit = manual;

              final fechaStr = DateFormat('dd/MM/yyyy').format(entryTime);

              tableData.add(<String>[
                fechaStr,
                nombreEmpleado,
                DateFormat('HH:mm').format(entryTime),
                DateFormat('HH:mm').format(time),
                _formatDuration(duration),
                if (isManualEntry || manualExit)
                  'CORRECCIÃƒâ€œN MANUAL'
                else
                  '',
              ]);

              entryTime = null; // Reset para siguiente ciclo
              isManualEntry = false;
            } else {
              // Salida huÃƒÂ©rfana (sin entrada)
              tableData.add(<String>[
                DateFormat('dd/MM/yyyy').format(time),
                nombreEmpleado,
                '---',
                DateFormat('HH:mm').format(time),
                '---',
                'Error: Falta entrada',
              ]);
            }
          }
        }

        // Si al acabar el bucle queda una entrada abierta
        if (entryTime != null) {
          tableData.add(<String>[
            DateFormat('dd/MM/yyyy').format(entryTime),
            nombreEmpleado,
            DateFormat('HH:mm').format(entryTime),
            'EN CURSO',
            '---',
            'Jornada activa',
          ]);
        }
      });

      // Ordenamos la tabla final por fecha
      tableData.sort((List<String> a, List<String> b) {
        try {
          final dateA = DateFormat('dd/MM/yyyy').parse(a[0]);
          final dateB = DateFormat('dd/MM/yyyy').parse(b[0]);
          return dateA.compareTo(dateB);
        } on Exception {
          return 0;
        }
      });

      // 5. GENERAR PDF
      final pdf = pw.Document();
      final headers = <String>[
        'Fecha',
        'Empleado',
        'Entrada',
        'Salida',
        'DuraciÃƒÂ³n',
        'Notas',
      ];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return <pw.Widget>[
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: <pw.Widget>[
                    pw.Text(
                      'Registro de Jornada - SALUFIT',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Periodo: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: tableData,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                cellStyle: const pw.TextStyle(fontSize: 9),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: <int, pw.AlignmentGeometry>{
                  0: pw.Alignment.center, // Fecha
                  2: pw.Alignment.center, // Entrada
                  3: pw.Alignment.center, // Salida
                  4: pw.Alignment.centerRight, // DuraciÃƒÂ³n
                },
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 20),
                child: pw.Text(
                  "* El cÃƒÂ¡lculo de duraciÃƒÂ³n se realiza automÃƒÂ¡ticamente entre fichaje de entrada y salida. Las filas marcadas como 'MANUAL' indican que la hora fue corregida por el empleado o sistema.",
                  style:
                      const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ),
            ];
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'informe_jornada_detallado.pdf',
      );
    } on Exception catch (e) {
      debugPrint('ERROR PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('Informes de Jornada'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Selecciona el rango:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
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
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: const Text('DESCARGAR INFORME DETALLADO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'El informe agrupa automÃƒÂ¡ticamente las entradas y salidas para calcular las horas trabajadas por sesiÃƒÂ³n.',
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
  const _DateCard({required this.label, required this.date});
  final String label;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Row(
            children: <Widget>[
              const Icon(Icons.calendar_today, size: 18, color: Colors.teal),
              const SizedBox(width: 8),
              Text(
                DateFormat('dd/MM/yyyy').format(date),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
