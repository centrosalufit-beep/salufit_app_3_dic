import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';

/// #11 — Pestaña Duplicados.
/// Muestra pacientes con +1 cita el mismo día para que recepción gestione
/// manualmente las extras (el bot envió un solo recordatorio para la
/// primera cita; las demás están marcadas como agrupadaConPrimera).
final duplicateAppointmentsProvider = StreamProvider<
    List<({String telefono, String nombre, List<DateTime> fechas, List<String> profs, List<DocumentReference> refs})>>((ref) {
  final db = ref.watch(firebaseFirestoreProvider);
  final now = Timestamp.now();
  return db
      .collection('clinni_appointments')
      .where('estado', isEqualTo: 'pendiente')
      .where('fechaCita', isGreaterThanOrEqualTo: now)
      .orderBy('fechaCita')
      .snapshots()
      .map((snap) {
    // Agrupar por (tel, día Madrid)
    final byKey = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final doc in snap.docs) {
      final d = doc.data();
      final tel = (d['pacienteTelefono'] as String?) ?? '';
      final f = (d['fechaCita'] as Timestamp?)?.toDate();
      if (tel.isEmpty || f == null) continue;
      // ISO local Madrid date
      final isoDay =
          '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
      final key = '${tel}_$isoDay';
      (byKey[key] ??= []).add(doc);
    }
    final out = <({
      String telefono,
      String nombre,
      List<DateTime> fechas,
      List<String> profs,
      List<DocumentReference> refs,
    })>[];
    for (final entry in byKey.entries) {
      if (entry.value.length < 2) continue;
      final first = entry.value.first.data();
      out.add((
        telefono: first['pacienteTelefono'] as String,
        nombre: (first['pacienteNombre'] as String?) ?? '?',
        fechas: entry.value
            .map((d) => (d.data()['fechaCita'] as Timestamp).toDate())
            .toList(),
        profs: entry.value
            .map((d) => (d.data()['profesional'] as String?) ?? '?')
            .toList(),
        refs: entry.value.map((d) => d.reference).toList(),
      ));
    }
    out.sort((a, b) => a.fechas.first.compareTo(b.fechas.first));
    return out;
  });
});

class DuplicatesTab extends ConsumerWidget {
  const DuplicatesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncs = ref.watch(duplicateAppointmentsProvider);
    final fmt = DateFormat('EEE d MMM HH:mm', 'es');

    return asyncs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (groups) {
        if (groups.isEmpty) {
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
                    'Sin pacientes con citas duplicadas',
                    style: TextStyle(
                        color: Colors.grey.shade700, fontSize: 14),
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
              color: Colors.blue.shade50,
              child: Text(
                '${groups.length} paciente(s) con varias citas el mismo día. '
                'El bot solo envió recordatorio de la PRIMERA. Las demás están '
                'marcadas como notificadas para evitar spam — gestiónalas tú '
                'manualmente.',
                style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final g = groups[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.nombre,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(g.telefono,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700)),
                          const SizedBox(height: 8),
                          ...List.generate(g.fechas.length, (j) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    j == 0
                                        ? Icons.notifications_active
                                        : Icons.notifications_off,
                                    size: 14,
                                    color: j == 0
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${fmt.format(g.fechas[j])} · ${g.profs[j]}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: j == 0
                                          ? Colors.green.shade900
                                          : Colors.grey.shade700,
                                      fontWeight: j == 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
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
}
