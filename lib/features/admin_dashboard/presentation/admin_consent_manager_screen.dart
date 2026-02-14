import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminConsentManagerScreen extends ConsumerWidget {
  const AdminConsentManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ejemplo de datos dummy, reemplaza con tu provider real
    final consents = <Map<String, dynamic>>[
      <String, dynamic>{'id': '1', 'user': 'Juan', 'status': 'pending'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Consentimientos')),
      body: ListView.builder(
        itemCount: consents.length,
        itemBuilder: (BuildContext context, int index) {
          final item = consents[index];

          // CORRECCIÓN: Extracción segura de datos dynamic
          final userName = item['user'] as String? ?? 'Usuario Desconocido';
          final status = item['status'] as String? ?? 'Desconocido';

          return ListTile(
            title: Text(userName),
            subtitle: Text(status),
            onTap: () => _showDetails(context, item),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // CORRECCIÓN: Tipado explícito en showDialog<void>
  Future<void> _showDetails(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    // CORRECCIÓN: Asignaciones seguras
    final userId = item['id']
        .toString(); // .toString() es seguro para ids numéricos o string
    final userNote = item['note'] as String? ?? 'Sin notas';

    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('Detalles ID: $userId'),
        content: Text(userNote),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // CORRECCIÓN: Tipado explícito en showModalBottomSheet<void>
  void _showAddModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: const Text('Formulario de Consentimiento'),
      ),
    );
  }
}
