import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/core/theme/app_colors.dart';

/// Stream de citas con problema: requireRevision=true (sin teléfono o
/// nombre ambiguo).
final problemAppointmentsProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final db = ref.watch(firebaseFirestoreProvider);
  return db
      .collection('clinni_appointments')
      .where('requiereRevision', isEqualTo: true)
      .where('estado', isEqualTo: 'pendiente')
      .orderBy('fechaCita')
      .snapshots()
      .map((snap) => snap.docs);
});

class ProblemAppointmentsTab extends ConsumerWidget {
  const ProblemAppointmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncs = ref.watch(problemAppointmentsProvider);
    final fmt = DateFormat('EEE d MMM yyyy HH:mm', 'es');

    return asyncs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (docs) {
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green),
                  const SizedBox(height: 12),
                  Text(
                    'Sin citas con problema',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Todas las citas pendientes tienen teléfono y datos válidos.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${docs.length} cita(s) requieren revisión manual. '
                      'Edita el teléfono o descarta si procede.',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final data = doc.data();
                  final fecha = (data['fechaCita'] as Timestamp?)?.toDate();
                  final fechaStr = fecha != null ? fmt.format(fecha) : '?';
                  final motivo = (data['motivoRevision'] as String?) ?? '?';
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: motivo == 'sin_telefono'
                                    ? Colors.red.shade100
                                    : Colors.orange.shade100,
                                child: Icon(
                                  motivo == 'sin_telefono'
                                      ? Icons.phone_disabled
                                      : Icons.help_outline,
                                  color: motivo == 'sin_telefono'
                                      ? Colors.red.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (data['pacienteNombre'] as String?) ??
                                          '(sin nombre)',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    Text(
                                      fechaStr,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700),
                                    ),
                                    Text(
                                      '${data['profesional'] ?? "?"}  ·  ${data['servicio'] ?? "?"}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: motivo == 'sin_telefono'
                                            ? Colors.red.shade50
                                            : Colors.orange.shade50,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        motivo == 'sin_telefono'
                                            ? '📵 Sin teléfono — paciente no encontrado en la base'
                                            : '⚠️ Nombre ambiguo (varios pacientes con ese nombre)',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: motivo == 'sin_telefono'
                                                ? Colors.red.shade900
                                                : Colors.orange.shade900),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Asignar teléfono'),
                                  onPressed: () =>
                                      _editPhoneDialog(context, ref, doc),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.cancel_outlined,
                                    size: 16),
                                label: const Text('Descartar'),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red),
                                onPressed: () => _discard(context, ref, doc),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editPhoneDialog(
    BuildContext context,
    WidgetRef ref,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final ctrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Asignar teléfono manualmente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paciente: ${doc.data()['pacienteNombre'] ?? "(?)"}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Introduce el teléfono en formato internacional sin "+":\n'
              'Ej: 34629011055 (España móvil 6XX/7XX)',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '34XXXXXXXXX',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (saved != true) return;

    final telRaw = ctrl.text.trim();
    final tel = telRaw.replaceAll(RegExp('[^0-9]'), '');
    if (!RegExp(r'^\d{9,15}$').hasMatch(tel)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Teléfono inválido. Debe tener 9-15 dígitos sin signos.')),
      );
      return;
    }
    final db = ref.read(firebaseFirestoreProvider);
    final user = FirebaseAuth.instance.currentUser;
    final data = doc.data();
    final nombre = (data['pacienteNombre'] as String?) ?? '';

    // 1) Actualizar la propia cita.
    await doc.reference.update({
      'pacienteTelefono': tel,
      'requiereRevision': false,
      'motivoRevision': null,
      'telefonoAsignadoEn': FieldValue.serverTimestamp(),
      'telefonoAsignadoPor': user?.uid,
    });

    // 2) Crear/actualizar el doc en clinni_patients (key = tel) para
    //    que futuras importaciones encuentren el match automáticamente.
    await db.collection('clinni_patients').doc(tel).set({
      'telefono': tel,
      'nombreCompleto': nombre,
      'origen': 'asignacion_manual_panel',
      'asignadoEn': FieldValue.serverTimestamp(),
      'asignadoPor': user?.uid,
    }, SetOptions(merge: true));

    // 3) Actualizar también otras citas pendientes del mismo paciente
    //    sin teléfono (mismo pacienteNombre) — caso típico.
    final otras = await db
        .collection('clinni_appointments')
        .where('pacienteNombre', isEqualTo: nombre)
        .where('requiereRevision', isEqualTo: true)
        .get();
    final batch = db.batch();
    for (final d in otras.docs) {
      if (d.id == doc.id) continue;
      batch.update(d.reference, {
        'pacienteTelefono': tel,
        'requiereRevision': false,
        'motivoRevision': null,
        'telefonoAsignadoEn': FieldValue.serverTimestamp(),
        'telefonoAsignadoPor': user?.uid,
      });
    }
    if (otras.docs.length > 1) await batch.commit();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Teléfono asignado. ${otras.docs.length} cita(s) del mismo paciente actualizadas.',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _discard(
    BuildContext context,
    WidgetRef ref,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Descartar cita'),
        content: const Text(
          'La cita se marcará como cancelada. ¿Confirmas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, descartar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await doc.reference.update({
      'estado': 'cancelada',
      'requiereRevision': false,
      'descartadaEn': FieldValue.serverTimestamp(),
      'motivoCancelacion': 'descartada_panel_problemas',
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cita descartada')),
    );
  }
}
