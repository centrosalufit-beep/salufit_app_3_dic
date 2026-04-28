import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/features/tasks/application/task_providers.dart';
import 'package:salufit_app/features/tasks/domain/task_model.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({
    required this.task,
    required this.currentUserId,
    required this.isReceivedView,
    super.key,
  });

  final TaskModel task;
  final String currentUserId;
  final bool isReceivedView;

  Color _estadoColor(TaskEstado e) {
    switch (e) {
      case TaskEstado.pendiente:
        return Colors.orange;
      case TaskEstado.enProgreso:
        return Colors.blue;
      case TaskEstado.finalizada:
        return Colors.green;
    }
  }

  String _fmtDate(DateTime d) {
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${d.day} ${meses[d.month - 1]} ${d.year}';
  }

  bool get _isVencida {
    if (task.estado == TaskEstado.finalizada) return false;
    final now = DateTime.now();
    return task.fechaLimite.isBefore(now);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Seguro que quieres eliminar "${task.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(taskRepositoryProvider).deleteTask(task.id);
  }

  Future<void> _cambiarEstado(WidgetRef ref, TaskEstado nuevo) async {
    await ref
        .read(taskRepositoryProvider)
        .updateEstado(taskId: task.id, nuevoEstado: nuevo);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _estadoColor(task.estado);
    final venceTexto = _fmtDate(task.fechaLimite);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    task.estado.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (task.descripcion.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.descripcion,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 15,
                  color: _isVencida ? Colors.red : Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  'Vence: $venceTexto',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isVencida ? Colors.red : Colors.grey.shade700,
                    fontWeight:
                        _isVencida ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (_isVencida) ...[
                  const SizedBox(width: 6),
                  const Text(
                    '(VENCIDA)',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  isReceivedView ? Icons.person_outline : Icons.person,
                  size: 15,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  isReceivedView
                      ? 'De: ${task.asignadorNombre}'
                      : 'Para: ${task.asignadoNombre}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildActions(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    if (isReceivedView) {
      // El asignado puede cambiar estado
      if (task.estado == TaskEstado.finalizada) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reabrir'),
              onPressed: () =>
                  _cambiarEstado(ref, TaskEstado.pendiente),
            ),
          ],
        );
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (task.estado == TaskEstado.pendiente)
            OutlinedButton.icon(
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Empezar'),
              onPressed: () => _cambiarEstado(ref, TaskEstado.enProgreso),
            ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009688),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Completar'),
            onPressed: () => _cambiarEstado(ref, TaskEstado.finalizada),
          ),
        ],
      );
    }
    // Vista de asignador: solo eliminar
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
          label: const Text(
            'Eliminar',
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () => _confirmDelete(context, ref),
        ),
      ],
    );
  }
}
