import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';

/// #12 — Pestaña Opt-outs.
/// Lista pacientes que han pedido la baja del bot. Botón "Reactivar" para
/// volver a permitir que el bot les envíe mensajes (admin lo decide tras
/// hablar con el paciente).
final optOutsProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final db = ref.watch(firebaseFirestoreProvider);
  return db
      .collection('whatsapp_optouts')
      .orderBy('fechaBaja', descending: true)
      .snapshots()
      .map((snap) => snap.docs);
});

class OptOutsTab extends ConsumerWidget {
  const OptOutsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncs = ref.watch(optOutsProvider);
    final fmt = DateFormat('d MMM yyyy HH:mm', 'es');

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
                  Icon(Icons.do_not_disturb_on_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Sin pacientes en opt-out',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    'Aquí aparecerán los pacientes que pidan baja del bot '
                    'escribiendo "baja", "unsubscribe", etc.',
                    style:
                        TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data();
            final fecha = (data['fechaBaja'] as Timestamp?)?.toDate();
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade50,
                  child: Icon(Icons.do_not_disturb_on,
                      color: Colors.red.shade700),
                ),
                title: Text(doc.id),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (fecha != null)
                      Text('Baja: ${fmt.format(fecha)}',
                          style: const TextStyle(fontSize: 12)),
                    if ((data['mensajeOriginal'] as String?)?.isNotEmpty ??
                        false)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '"${data['mensajeOriginal']}"',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reactivar'),
                  onPressed: () => _reactivate(context, doc),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _reactivate(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reactivar paciente'),
        content: Text(
          'El paciente ${doc.id} podrá volver a recibir mensajes automáticos del bot.\n\n'
          '¿Confirmas la reactivación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await doc.reference.delete();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paciente reactivado')),
    );
  }
}
