import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/core/theme/app_colors.dart';

final pendingAppointmentsProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final db = ref.watch(firebaseFirestoreProvider);
  return db
      .collection('clinni_appointments_pending')
      .where('estado', isEqualTo: 'pendiente_validacion')
      .orderBy('fechaCita')
      .snapshots()
      .map((snap) => snap.docs);
});

class PendingAppointmentsTab extends ConsumerWidget {
  const PendingAppointmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingAppointmentsProvider);
    final fmt = DateFormat('EEE d MMM yyyy HH:mm', 'es');
    return pendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (appts) {
        if (appts.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 56,
                    color: Color(0xFF1E293B),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Sin citas pendientes de validación',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Las citas que un paciente nuevo haya elegido por '
                    'WhatsApp aparecerán aquí esperando aprobación.',
                    style: TextStyle(
                      color: Color(0xFF454545),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: appts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = appts[i];
            final data = doc.data();
            final fecha = (data['fechaCita'] as Timestamp?)?.toDate();
            final fechaStr = fecha != null ? fmt.format(fecha) : '?';
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.15),
                      child: const Icon(Icons.event,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (data['pacienteNombre'] as String?) ??
                                '(sin nombre)',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (data['pacienteTelefono'] as String?) ?? '',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$fechaStr  ·  ${data['profesional'] ?? "?"}  ·  ${data['servicio'] ?? "?"}',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade800),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Aprobar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(110, 32),
                          ),
                          onPressed: () => _approve(context, ref, doc),
                        ),
                        const SizedBox(height: 4),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Rechazar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            minimumSize: const Size(110, 32),
                          ),
                          onPressed: () => _reject(context, ref, doc),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final db = ref.read(firebaseFirestoreProvider);
    final data = doc.data();
    // Crear cita real en clinni_appointments.
    await db.collection('clinni_appointments').add({
      'pacienteNombre': data['pacienteNombre'],
      'pacienteTelefono': data['pacienteTelefono'],
      'fechaCita': data['fechaCita'],
      'profesional': data['profesional'],
      'servicio': data['servicio'],
      'estado': 'pendiente',
      'recordatorioEnviado': false,
      'fechaRecordatorio': null,
      'origenExcel': 'whatsapp_bot_lead_aprobado',
      'importadoEn': FieldValue.serverTimestamp(),
      'creadoPor': 'panel_admin/aprobar_pending',
    });
    await doc.reference.update({
      'estado': 'aprobada',
      'aprobadaEn': FieldValue.serverTimestamp(),
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cita aprobada y creada en clinni_appointments. '
          'Recuerda registrarla también en Clinni.',
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    await doc.reference.update({
      'estado': 'rechazada',
      'rechazadaEn': FieldValue.serverTimestamp(),
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cita rechazada')),
    );
  }
}
