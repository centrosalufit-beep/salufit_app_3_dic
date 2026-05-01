import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/core/theme/app_colors.dart';

/// Stream de leads pendientes en `clinni_patients_pending`.
final leadsPendingProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final db = ref.watch(firebaseFirestoreProvider);
  return db
      .collection('clinni_patients_pending')
      .where('estado', isEqualTo: 'pendiente_validacion')
      .orderBy('creadoEn', descending: true)
      .snapshots()
      .map((snap) => snap.docs);
});

class LeadsPendingTab extends ConsumerWidget {
  const LeadsPendingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(leadsPendingProvider);
    final fmt = DateFormat('d/M/yyyy HH:mm');
    return leadsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (leads) {
        if (leads.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_alt,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'Sin leads pendientes',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'El bot los irá registrando aquí cuando un número '
                    'desconocido pida cita por WhatsApp.',
                    style: TextStyle(
                      color: Colors.grey.shade400,
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
          itemCount: leads.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final lead = leads[i];
            final data = lead.data();
            final creadoTs = data['creadoEn'] as Timestamp?;
            final creadoStr = creadoTs != null
                ? fmt.format(creadoTs.toDate())
                : '?';
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (data['nombreCompleto'] as String?) ?? '(sin nombre)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (data['telefono'] as String?) ?? '',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _Pill(
                                icon: Icons.medical_services,
                                text: (data['servicioInteres'] as String?)
                                        ?.isNotEmpty ==
                                    true
                                    ? data['servicioInteres'] as String
                                    : '(sin servicio)',
                              ),
                              _Pill(
                                icon: Icons.access_time,
                                text: (data['preferenciaHoraria'] as String?)
                                        ?.isNotEmpty ==
                                    true
                                    ? data['preferenciaHoraria'] as String
                                    : '(sin preferencia)',
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Recibido $creadoStr',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Aprobar'),
                          onPressed: () => _approve(context, ref, lead),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(110, 32),
                          ),
                        ),
                        const SizedBox(height: 4),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Descartar'),
                          onPressed: () => _discard(context, ref, lead),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            minimumSize: const Size(110, 32),
                          ),
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
    QueryDocumentSnapshot<Map<String, dynamic>> lead,
  ) async {
    final db = ref.read(firebaseFirestoreProvider);
    final data = lead.data();
    final telefono = (data['telefono'] as String?) ?? lead.id;

    // Crear ficha en clinni_patients (idempotente — doc ID = teléfono).
    await db.collection('clinni_patients').doc(telefono).set({
      'numeroHistoria': '',
      'nombreCompleto': data['nombreCompleto'] ?? '',
      'sexo': '',
      'dni': '',
      'telefono': telefono,
      'email': '',
      'fechaNacimiento': null,
      'derivadoPor': '',
      'etiquetas': ['lead_whatsapp'],
      'recibirMailing': false,
      'proteccionDatosFirmada': false,
      'infoSegundoTutor': '',
      'origenExcel': 'whatsapp_bot_lead',
      'importadoEn': FieldValue.serverTimestamp(),
      'servicioInteres': data['servicioInteres'],
      'preferenciaHoraria': data['preferenciaHoraria'],
    }, SetOptions(merge: true));

    // Marcar lead como aprobado (no borramos, queremos auditoría).
    await lead.reference.update({
      'estado': 'aprobado',
      'aprobadoEn': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lead aprobado y creado en clinni_patients'),
      ),
    );
  }

  Future<void> _discard(
    BuildContext context,
    WidgetRef ref,
    QueryDocumentSnapshot<Map<String, dynamic>> lead,
  ) async {
    await lead.reference.update({
      'estado': 'descartado',
      'descartadoEn': FieldValue.serverTimestamp(),
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lead descartado')),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
