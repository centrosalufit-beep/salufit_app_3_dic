import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:salufit_app/features/bookings/presentation/widgets/create_class_batch_dialog.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_class_list_screen.dart';

class AdminClassManagerScreen extends StatelessWidget {
  const AdminClassManagerScreen({
    required this.currentUserId,
    required this.userRole,
    super.key,
  });
  final String currentUserId;
  final String userRole;

  bool get _isAdmin =>
      userRole == 'admin' || userRole == 'administrador';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // Replicar mes / generar cuadrante son operaciones administrativas:
      // solo admin las ve. Profesionales solo consultan.
      floatingActionButton: _isAdmin
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'replicate',
                  onPressed: () => _showReplicateDialog(context),
                  backgroundColor: const Color(0xFF1E293B),
                  icon: const Icon(Icons.copy_all, color: Colors.white),
                  label: const Text(
                    'REPLICAR MES ANTERIOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'generate',
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => const CreateClassBatchDialog(),
                  ),
                  backgroundColor: const Color(0xFF009688),
                  icon: const Icon(Icons.calendar_month, color: Colors.white),
                  label: const Text(
                    'GENERAR CUADRANTE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          : null,
      body: ClientClassListScreen(userId: currentUserId, userRole: userRole),
    );
  }

  Future<void> _showReplicateDialog(BuildContext context) async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final nextMonth = DateTime(now.year, now.month + 1);

    final initial = (
      source: DateTime(lastMonth.year, lastMonth.month),
      target: DateTime(now.year, now.month),
    );

    final selected = await showDialog<({DateTime source, DateTime target})>(
      context: context,
      builder: (dialogCtx) => _ReplicateDialog(
        initialSource: initial.source,
        initialTarget: initial.target,
        nextMonth: nextMonth,
      ),
    );
    if (selected == null || !context.mounted) return;

    // Mostrar progreso modal mientras llamamos a la CF.
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Sin usuario autenticado');
      final idToken = await user.getIdToken();
      final url = Uri.parse(
        'https://europe-southwest1-salufitnewapp.cloudfunctions.net/replicateClassesMonth',
      );
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sourceMonth': _ymKey(selected.source),
          'targetMonth': _ymKey(selected.target),
        }),
      );
      if (context.mounted) Navigator.of(context).pop(); // cierra el progress

      final data = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw StateError(
          (data['error'] as String?) ?? 'HTTP ${response.statusCode}',
        );
      }
      final created = (data['created'] as num?)?.toInt() ?? 0;
      final existed = (data['alreadyExisted'] as num?)?.toInt() ?? 0;
      final skipped = (data['skippedHolidays'] as num?)?.toInt() ?? 0;
      final patterns = (data['patternsExtracted'] as num?)?.toInt() ?? 0;
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Replicación completada'),
          content: Text(
            'Patrones detectados en ${_ymKey(selected.source)}: $patterns\n\n'
            'Clases creadas en ${_ymKey(selected.target)}: $created\n'
            'Ya existían: $existed\n'
            'Saltadas por festivo: $skipped',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop(); // cierra progress
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _ymKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

class _ReplicateDialog extends StatefulWidget {
  const _ReplicateDialog({
    required this.initialSource,
    required this.initialTarget,
    required this.nextMonth,
  });

  final DateTime initialSource;
  final DateTime initialTarget;
  final DateTime nextMonth;

  @override
  State<_ReplicateDialog> createState() => _ReplicateDialogState();
}

class _ReplicateDialogState extends State<_ReplicateDialog> {
  late DateTime _source;
  late DateTime _target;

  @override
  void initState() {
    super.initState();
    _source = widget.initialSource;
    _target = widget.initialTarget;
  }

  @override
  Widget build(BuildContext context) {
    final monthNames = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    String monthLabel(DateTime d) => '${monthNames[d.month - 1]} ${d.year}';

    return AlertDialog(
      title: const Text('Replicar clases del mes'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lee las clases del mes origen y crea instancias en el mes '
              'destino para cada día de la semana correspondiente. Idempotente: '
              'si ya existen, no se duplican. Respeta festivos del centro.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: Colors.indigo),
              title: const Text('Mes origen'),
              subtitle: Text(monthLabel(_source)),
              trailing: TextButton(
                onPressed: _pickSource,
                child: const Text('Cambiar'),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month,
                  color: Color(0xFF009688)),
              title: const Text('Mes destino'),
              subtitle: Text(monthLabel(_target)),
              trailing: TextButton(
                onPressed: _pickTarget,
                child: const Text('Cambiar'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy_all),
          label: const Text('Replicar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop((
            source: _source,
            target: _target,
          )),
        ),
      ],
    );
  }

  Future<void> _pickSource() async {
    final picked = await _pickMonth(_source);
    if (picked != null) setState(() => _source = picked);
  }

  Future<void> _pickTarget() async {
    final picked = await _pickMonth(_target);
    if (picked != null) setState(() => _target = picked);
  }

  Future<DateTime?> _pickMonth(DateTime initial) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
      helpText: 'Selecciona cualquier día del mes',
    );
    if (picked == null) return null;
    return DateTime(picked.year, picked.month);
  }
}
