import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

class ProfessionalTasksScreen extends ConsumerWidget {
  const ProfessionalTasksScreen({required this.userId, super.key});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tareas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewTaskDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            ColoredBox(
              color: AppColors.primary.withValues(alpha: 0.05),
              child: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'PENDIENTES'),
                  Tab(text: 'COMPLETADAS'),
                  Tab(text: 'ENVIADAS'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _TaskList(
                    userId: userId,
                    mode: _TaskMode.pending,
                  ),
                  _TaskList(
                    userId: userId,
                    mode: _TaskMode.completed,
                  ),
                  _TaskList(
                    userId: userId,
                    mode: _TaskMode.sent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNewTaskDialog(BuildContext context, WidgetRef ref) async {
    final db = ref.read(firebaseFirestoreProvider);
    final profesionales = await _loadProfesionales(db);
    if (!context.mounted) return;

    String? asignadoAId;
    String? asignadoANombre;
    var fechaLimite = DateTime.now().add(const Duration(days: 1));
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.task_alt, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Nueva Tarea'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: Llamar paciente 3421',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Asignar a',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: profesionales
                      .map(
                        (p) => DropdownMenuItem(
                          value: p['id'] as String,
                          child: Text(p['nombre'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDs(() {
                    asignadoAId = v;
                    asignadoANombre = profesionales
                        .firstWhere((p) => p['id'] == v)['nombre'] as String;
                  }),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event, color: AppColors.primary),
                  title: Text(
                    'Límite: ${DateFormat('dd/MM/yyyy').format(fechaLimite)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: fechaLimite,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDs(() => fechaLimite = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed:
                  (asignadoAId != null && tituloCtrl.text.trim().isNotEmpty)
                      ? () => Navigator.pop(ctx, true)
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('ASIGNAR'),
            ),
          ],
        ),
      ),
    );

    if (result != true || asignadoAId == null) return;

    // Resolver nombre del creador
    var creadoPorNombre = userId;
    try {
      final doc = await db.collection('users_app').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        creadoPorNombre = data.safeString('nombreCompleto').isNotEmpty
            ? data.safeString('nombreCompleto')
            : data.safeString('nombre');
      }
    } catch (_) {}

    await db.collection('staff_tasks').add({
      'titulo': tituloCtrl.text.trim(),
      'descripcion': descCtrl.text.trim(),
      'creadoPorId': userId,
      'creadoPorNombre': creadoPorNombre,
      'asignadoAId': asignadoAId,
      'asignadoANombre': asignadoANombre,
      'fechaLimite': Timestamp.fromDate(fechaLimite),
      'estado': 'pendiente',
      'fechaCreacion': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tarea asignada a $asignadoANombre'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadProfesionales(FirebaseFirestore db) async {
    final snap = await db
        .collection('users_app')
        .where(
          'rol',
          whereIn: const ['admin', 'administrador', 'profesional'],
        )
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return {
        'id': d.id,
        'nombre': data.safeString('nombreCompleto').isNotEmpty
            ? data.safeString('nombreCompleto')
            : data.safeString('nombre'),
      };
    }).toList();
  }
}

// ═══════════════════════════════════════════════════════════════
// LISTA DE TAREAS
// ═══════════════════════════════════════════════════════════════

enum _TaskMode { pending, completed, sent }

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.userId, required this.mode});
  final String userId;
  final _TaskMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Query query = ref.watch(firebaseFirestoreProvider).collection('staff_tasks');

    // Query simple sin orderBy compuesto (evita índices)
    switch (mode) {
      case _TaskMode.pending:
        query = query
            .where('asignadoAId', isEqualTo: userId)
            .where('estado', isEqualTo: 'pendiente');
      case _TaskMode.completed:
        query = query
            .where('asignadoAId', isEqualTo: userId)
            .where('estado', isEqualTo: 'completada');
      case _TaskMode.sent:
        query = query
            .where('creadoPorId', isEqualTo: userId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.limit(50).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        // Ordenar en código
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final dataA = a.data()! as Map<String, dynamic>;
            final dataB = b.data()! as Map<String, dynamic>;
            final tsA = (dataA['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime(1970);
            final tsB = (dataB['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime(1970);
            return tsB.compareTo(tsA); // Más reciente primero
          });
        if (docs.isEmpty) {
          final msg = switch (mode) {
            _TaskMode.pending => 'Sin tareas pendientes',
            _TaskMode.completed => 'Sin tareas completadas',
            _TaskMode.sent => 'No has enviado tareas',
          };
          return Center(
            child: Text(msg, style: const TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data()! as Map<String, dynamic>;
            return _TaskCard(
              doc: docs[i],
              data: data,
              mode: mode,
            );
          },
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.doc,
    required this.data,
    required this.mode,
  });
  final QueryDocumentSnapshot doc;
  final Map<String, dynamic> data;
  final _TaskMode mode;

  @override
  Widget build(BuildContext context) {
    final titulo = data.safeString('titulo');
    final desc = data.safeString('descripcion');
    final estado = data.safeString('estado');
    final isPending = estado == 'pendiente';
    final limite = data.safeDateTime('fechaLimite');
    final isOverdue = isPending && limite.isBefore(DateTime.now());
    final dateFormat = DateFormat('dd/MM/yyyy');

    final subtitle = switch (mode) {
      _TaskMode.pending =>
        'De: ${data.safeString('creadoPorNombre')} · Límite: ${dateFormat.format(limite)}',
      _TaskMode.completed =>
        'Completada: ${dateFormat.format(data.safeDateTime('completadaEl'))}',
      _TaskMode.sent =>
        'Para: ${data.safeString('asignadoANombre')} · ${isPending ? "Pendiente" : "Completada"}',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isOverdue ? Colors.red.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPending
              ? isOverdue
                  ? Colors.red.shade100
                  : Colors.orange.shade100
              : Colors.green.shade100,
          child: Icon(
            isPending ? Icons.pending_actions : Icons.check_circle,
            color: isPending
                ? isOverdue
                    ? Colors.red
                    : Colors.orange
                : Colors.green,
          ),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration:
                isPending ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: const TextStyle(fontSize: 11)),
            if (desc.isNotEmpty)
              Text(
                desc,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: mode == _TaskMode.pending
            ? IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                onPressed: () => doc.reference.update({
                  'estado': 'completada',
                  'completadaEl': FieldValue.serverTimestamp(),
                }),
              )
            : null,
      ),
    );
  }
}
