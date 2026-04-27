import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/patient_record/presentation/video_player_screen.dart';

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
    final type = data.safeString('type');
    final isVideoFeedback = type == 'video_difficulty_red';
    final reportCount = data.safeInt('reportCount');

    final subtitle = switch (mode) {
      _TaskMode.pending =>
        'De: ${data.safeString('creadoPorNombre')} · Límite: ${dateFormat.format(limite)}',
      _TaskMode.completed =>
        'Completada: ${dateFormat.format(data.safeDateTime('completadaEl'))}',
      _TaskMode.sent =>
        'Para: ${data.safeString('asignadoANombre')} · ${isPending ? "Pendiente" : "Completada"}',
    };

    final feedbackTone = isVideoFeedback ? Colors.red.shade50 : null;
    final cardColor = isOverdue ? Colors.red.shade50 : feedbackTone;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      child: ListTile(
        onTap: isVideoFeedback
            ? () => _showVideoFeedbackDetail(context, data, doc.reference)
            : null,
        leading: _buildLeadingAvatar(
          isPending: isPending,
          isOverdue: isOverdue,
          isVideoFeedback: isVideoFeedback,
          reportCount: reportCount,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration:
                      isPending ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            if (isVideoFeedback)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_outlined,
                        size: 12, color: Colors.red.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Feedback',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: const TextStyle(fontSize: 11)),
            if (isVideoFeedback) ...[
              const SizedBox(height: 2),
              Text(
                'Cliente: ${data.safeString('clientName')} · Ejercicio: ${data.safeString('exerciseName')}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (reportCount > 1)
                Text(
                  '⚠️ Reportado $reportCount veces',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ] else if (desc.isNotEmpty)
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
                tooltip: 'Marcar como completada',
                onPressed: () => doc.reference.update({
                  'estado': 'completada',
                  'completadaEl': FieldValue.serverTimestamp(),
                }),
              )
            : null,
      ),
    );
  }

  Widget _buildLeadingAvatar({
    required bool isPending,
    required bool isOverdue,
    required bool isVideoFeedback,
    required int reportCount,
  }) {
    if (isVideoFeedback && isPending) {
      return Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Colors.red.shade100,
            child: Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade700),
          ),
          if (reportCount > 1)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  '$reportCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    }
    return CircleAvatar(
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
    );
  }

  Future<void> _showVideoFeedbackDetail(
    BuildContext context,
    Map<String, dynamic> data,
    DocumentReference docRef,
  ) async {
    final clientName = data.safeString('clientName');
    final exerciseName = data.safeString('exerciseName');
    final reportCount = data.safeInt('reportCount');
    final firstReport = data.safeDateTime('firstReportAt');
    final lastReport = data.safeDateTime('lastReportAt');
    final isPending = data.safeString('estado') == 'pendiente';
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 10),
            const Expanded(child: Text('Dificultad alta reportada')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow(Icons.person_outline, 'Cliente', clientName),
              _detailRow(Icons.fitness_center, 'Ejercicio', exerciseName),
              _detailRow(
                Icons.repeat,
                'Reportes',
                reportCount > 1
                    ? '$reportCount veces'
                    : 'Primer reporte',
              ),
              _detailRow(
                Icons.first_page,
                'Primer reporte',
                dateFormat.format(firstReport),
              ),
              _detailRow(
                Icons.last_page,
                'Último reporte',
                dateFormat.format(lastReport),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Text(
                  'Sugerido: contacta al cliente para revisar la progresión '
                  'o sustituir el ejercicio por otro adecuado.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.play_circle_outline, size: 18),
            label: const Text('VER VÍDEO'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => VideoPlayerScreen(
                    videoUrl: data.safeString('videoUrl'),
                    title: exerciseName.isNotEmpty
                        ? exerciseName
                        : 'Ejercicio',
                    assignmentId: data.safeString('assignmentId'),
                  ),
                ),
              );
            },
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CERRAR'),
              ),
              if (isPending) ...[
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('MARCAR RESUELTA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await docRef.update({
                      'estado': 'completada',
                      'completadaEl': FieldValue.serverTimestamp(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
