import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

class AdminTimeReportScreen extends StatefulWidget {
  const AdminTimeReportScreen({super.key});
  @override
  State<AdminTimeReportScreen> createState() => _AdminTimeReportScreenState();
}

class _AdminTimeReportScreenState extends State<AdminTimeReportScreen> {
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  bool _loading = false;
  List<_DayRecord> _records = [];
  final _userNameCache = <String, String>{};

  /// Resuelve el nombre: primero del campo inline, luego de users_app, luego UID.
  Future<String> _resolveUserName(
    String userId, {
    String inlineName = '',
  }) async {
    // Si ya viene el nombre en el registro, usarlo directamente
    if (inlineName.isNotEmpty) {
      _userNameCache[userId] = inlineName;
      return inlineName;
    }
    if (_userNameCache.containsKey(userId)) return _userNameCache[userId]!;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users_app')
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        // Intentar nombreCompleto primero, luego nombre+apellidos
        final full = data.safeString('nombreCompleto');
        if (full.isNotEmpty) {
          _userNameCache[userId] = full;
          return full;
        }
        final name =
            '${data.safeString('nombre')} ${data.safeString('apellidos')}'
                .trim();
        if (name.isNotEmpty) {
          _userNameCache[userId] = name;
          return name;
        }
        // Fallback: email
        final email = data.safeString('email');
        if (email.isNotEmpty) {
          _userNameCache[userId] = email;
          return email;
        }
      }
    } catch (_) {}
    _userNameCache[userId] = userId;
    return userId;
  }

  Future<void> _fetchRecords() async {
    setState(() => _loading = true);
    try {
      final start = DateTime(
        _range.start.year,
        _range.start.month,
        _range.start.day,
      );
      final end = DateTime(
        _range.end.year,
        _range.end.month,
        _range.end.day,
        23,
        59,
        59,
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('timeClockRecords')
          .where('timestamp', isGreaterThanOrEqualTo: start)
          .where('timestamp', isLessThanOrEqualTo: end)
          .orderBy('timestamp')
          .get();

      // Agrupar por usuario
      final byUser = <String, List<Map<String, dynamic>>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final uid = data.safeString('userId');
        if (uid.isEmpty) continue;
        byUser.putIfAbsent(uid, () => []).add(data);
      }

      final results = <_DayRecord>[];

      for (final entry in byUser.entries) {
        // Buscar nombre inline en cualquier evento del usuario
        final inlineName = entry.value
            .map((e) => e.safeString('userName'))
            .firstWhere((n) => n.isNotEmpty, orElse: () => '');
        final userName = await _resolveUserName(
          entry.key,
          inlineName: inlineName,
        );
        final events = entry.value;

        // Emparejar IN/OUT
        for (var i = 0; i < events.length; i++) {
          final ev = events[i];
          if (ev.safeString('type') != 'IN') continue;

          final entryTime = ev.safeDateTime('timestamp');
          DateTime? exitTime;
          Duration? duration;

          // Buscar el siguiente OUT del mismo usuario
          for (var j = i + 1; j < events.length; j++) {
            if (events[j].safeString('type') == 'OUT') {
              exitTime = events[j].safeDateTime('timestamp');
              duration = exitTime.difference(entryTime);
              i = j; // Saltar al siguiente par
              break;
            }
          }

          results.add(
            _DayRecord(
              userName: userName,
              date: entryTime,
              entryTime: entryTime,
              exitTime: exitTime,
              duration: duration,
              device: ev.safeString('device', defaultValue: '-'),
            ),
          );
        }
      }

      // Ordenar por fecha
      results.sort((a, b) => a.date.compareTo(b.date));

      if (mounted) {
        setState(() {
          _records = results;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching time records: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _range,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF009688),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _range = picked);
      await _fetchRecords();
    }
  }

  String _formatDuration(Duration? d) {
    if (d == null) return 'Abierta';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }

  Future<void> _generatePdf() async {
    if (_records.isEmpty) return;

    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Centro Salufit — Informe de Jornada',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Período: ${dateFormat.format(_range.start)} - ${dateFormat.format(_range.end)}',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generado: ${dateFormat.format(DateTime.now())} ${timeFormat.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
            },
            headers: [
              'Profesional',
              'Fecha',
              'Entrada',
              'Salida',
              'Duración',
              'Dispositivo',
            ],
            data: _records
                .map(
                  (r) => [
                    r.userName,
                    dateFormat.format(r.date),
                    timeFormat.format(r.entryTime),
                    if (r.exitTime != null) timeFormat.format(r.exitTime!) else '—',
                    _formatDuration(r.duration),
                    r.device,
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 20),
          _buildSummaryTable(dateFormat),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name:
          'Informe_Jornada_${dateFormat.format(_range.start)}_${dateFormat.format(_range.end)}',
    );
  }

  pw.Widget _buildSummaryTable(DateFormat dateFormat) {
    // Resumen por profesional
    final summary = <String, Duration>{};
    final openSessions = <String, int>{};

    for (final r in _records) {
      if (r.duration != null) {
        summary[r.userName] =
            (summary[r.userName] ?? Duration.zero) + r.duration!;
      } else {
        openSessions[r.userName] = (openSessions[r.userName] ?? 0) + 1;
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Resumen por Profesional',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          headers: ['Profesional', 'Total Horas', 'Sesiones Abiertas'],
          data: summary.entries
              .map(
                (e) => [
                  e.key,
                  _formatDuration(e.value),
                  '${openSessions[e.key] ?? 0}',
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Barra de controles
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range, color: Colors.tealAccent),
                const SizedBox(width: 12),
                Text(
                  '${dateFormat.format(_range.start)} — ${dateFormat.format(_range.end)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _selectDateRange,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.tealAccent),
                    foregroundColor: Colors.tealAccent,
                  ),
                  child: const Text('CAMBIAR'),
                ),
                const Spacer(),
                Text(
                  '${_records.length} registros',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _records.isEmpty ? null : _generatePdf,
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('GENERAR PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(color: Color(0xFF009688)),
          // Tabla de resultados
          Expanded(
            child: _records.isEmpty && !_loading
                ? const Center(
                    child: Text(
                      'Sin registros en este período',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _records.length,
                    itemBuilder: (context, i) {
                      final r = _records[i];
                      final isOpen = r.exitTime == null;
                      return Card(
                        color: Colors.white.withValues(alpha: 0.9),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isOpen
                                ? Colors.orange.shade100
                                : Colors.teal.shade50,
                            child: Icon(
                              isOpen ? Icons.warning_amber : Icons.check_circle,
                              color: isOpen ? Colors.orange : Colors.teal,
                            ),
                          ),
                          title: Text(
                            r.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${dateFormat.format(r.date)} · '
                            '${timeFormat.format(r.entryTime)} → '
                            '${r.exitTime != null ? timeFormat.format(r.exitTime!) : "—"}'
                            ' · ${r.device}',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? Colors.orange.shade50
                                  : Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatDuration(r.duration),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isOpen ? Colors.orange.shade700 : Colors.teal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DayRecord {
  const _DayRecord({
    required this.userName,
    required this.date,
    required this.entryTime,
    required this.device,
    this.exitTime,
    this.duration,
  });

  final String userName;
  final DateTime date;
  final DateTime entryTime;
  final DateTime? exitTime;
  final Duration? duration;
  final String device;
}
