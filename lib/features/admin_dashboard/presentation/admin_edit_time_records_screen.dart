import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

class AdminEditTimeRecordsScreen extends StatefulWidget {
  const AdminEditTimeRecordsScreen({super.key});
  @override
  State<AdminEditTimeRecordsScreen> createState() =>
      _AdminEditTimeRecordsScreenState();
}

class _AdminEditTimeRecordsScreenState
    extends State<AdminEditTimeRecordsScreen> {
  DateTime _selectedDate = DateTime.now();
  final _userNameCache = <String, String>{};

  /// Resuelve el nombre: primero del campo inline, luego de users_app, luego UID.
  Future<String> _resolveUserName(
    String userId, {
    String inlineName = '',
  }) async {
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

  Future<void> _editRecord(DocumentSnapshot doc) async {
    final data = doc.data()! as Map<String, dynamic>;
    final currentTime = data.safeDateTime('timestamp');
    final currentType = data.safeString('type');

    var selectedType = currentType;
    var selectedTime = TimeOfDay.fromDateTime(currentTime);

    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar fichaje'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'IN', child: Text('ENTRADA')),
                  DropdownMenuItem(value: 'OUT', child: Text('SALIDA')),
                ],
                onChanged: (v) =>
                    setDialogState(() => selectedType = v ?? currentType),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time, color: Color(0xFF009688)),
                title: Text(
                  'Hora: ${selectedTime.format(ctx)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setDialogState(() => selectedTime = picked);
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Fecha: ${DateFormat('dd/MM/yyyy').format(currentTime)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () => _confirmDelete(ctx, doc.id),
              child: const Text(
                'ELIMINAR',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {
                'type': selectedType,
                'time': selectedTime,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                foregroundColor: Colors.white,
              ),
              child: const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    final newTime = result['time'] as TimeOfDay;
    final updatedTimestamp = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      newTime.hour,
      newTime.minute,
    );

    await FirebaseFirestore.instance
        .collection('timeClockRecords')
        .doc(doc.id)
        .update({
      'type': result['type'] as String,
      'timestamp': Timestamp.fromDate(updatedTimestamp),
      'isManualEntry': true,
      'editedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fichaje actualizado'),
          backgroundColor: Color(0xFF009688),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext dialogCtx, String docId) async {
    final confirm = await showDialog<bool>(
      context: dialogCtx,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar fichaje'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'ELIMINAR',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      await FirebaseFirestore.instance
          .collection('timeClockRecords')
          .doc(docId)
          .delete();
      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fichaje eliminado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final end = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      23,
      59,
      59,
    );
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Calendario lateral
          SizedBox(
            width: 320,
            child: ColoredBox(
              color: Colors.white.withValues(alpha: 0.85),
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                onDateChanged: (d) => setState(() => _selectedDate = d),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // Lista de fichajes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_calendar,
                        color: Colors.tealAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Fichajes del ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('timeClockRecords')
                        .where('timestamp', isGreaterThanOrEqualTo: start)
                        .where('timestamp', isLessThanOrEqualTo: end)
                        .orderBy('timestamp')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'No hay registros para este día.',
                              style: TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final data =
                              docs[i].data()! as Map<String, dynamic>;
                          final userId = data.safeString('userId');
                          final type = data.safeString('type');
                          final fechaRegistro = data.safeDateTime('timestamp');
                          final isIn = type == 'IN';
                          final device =
                              data.safeString('device', defaultValue: '-');
                          final isManual = data.safeBool('isManualEntry');

                          final inlineName =
                              data.safeString('userName');

                          return FutureBuilder<String>(
                            future: _resolveUserName(
                              userId,
                              inlineName: inlineName,
                            ),
                            builder: (context, nameSnap) {
                              final displayName =
                                  nameSnap.data ?? 'Cargando...';
                              return Card(
                                color:
                                    Colors.white.withValues(alpha: 0.9),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isIn
                                        ? Colors.teal.shade50
                                        : Colors.orange.shade50,
                                    child: Icon(
                                      isIn ? Icons.login : Icons.logout,
                                      color: isIn
                                          ? Colors.teal
                                          : Colors.orange,
                                    ),
                                  ),
                                  title: Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${isIn ? "ENTRADA" : "SALIDA"} · '
                                    '${timeFormat.format(fechaRegistro)} · '
                                    '$device'
                                    '${isManual ? " · (editado)" : ""}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () => _editRecord(docs[i]),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
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
