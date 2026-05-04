import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/professional/presentation/professional_tasks_screen.dart';

class ProfessionalDesktopDashboardScreen extends ConsumerWidget {
  const ProfessionalDesktopDashboardScreen({
    required this.userId,
    required this.userRole,
    super.key,
  });

  final String userId;
  final String userRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _WelcomeHeader(),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _PendingTasksPanel(userId: userId),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: _MiniCrmPanel(userId: userId),
                        ),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PendingTasksPanel(userId: userId),
                      const SizedBox(height: 20),
                      _MiniCrmPanel(userId: userId),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : (hour < 20 ? 'Buenas tardes' : 'Buenas noches');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Resumen de tu jornada profesional',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _PendingTasksPanel extends ConsumerWidget {
  const _PendingTasksPanel({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: ref
            .watch(firebaseFirestoreProvider)
            .collection('staff_tasks')
            .where('asignadoAId', isEqualTo: userId)
            .where('estado', isEqualTo: 'pendiente')
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'TAREAS PENDIENTES',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.2,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ProfessionalTasksScreen(userId: userId),
                      ),
                    ),
                    child: const Text('Ver todas'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Sin tareas pendientes',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...docs.map((doc) {
                  final data = doc.data()! as Map<String, dynamic>;
                  final titulo = data.safeString('titulo');
                  final from = data.safeString('creadoPorNombre');
                  final limite = data.safeDateTime('fechaLimite');
                  final isOverdue = limite.isBefore(DateTime.now());
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? Colors.red.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOverdue
                            ? Colors.red.shade200
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.task_alt,
                          color: isOverdue ? Colors.red : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'De: $from · Límite: ${limite.day.toString().padLeft(2, '0')}/${limite.month.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isOverdue
                                      ? Colors.red.shade700
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          onPressed: () => doc.reference.update({
                            'estado': 'completada',
                            'completadaEl': FieldValue.serverTimestamp(),
                          }),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _MiniCrmPanel extends ConsumerWidget {
  const _MiniCrmPanel({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: ref
            .watch(firebaseFirestoreProvider)
            .collection('crm_entries')
            .where('profesionalId', isEqualTo: userId)
            .where('mes', isEqualTo: now.month)
            .where('anio', isEqualTo: now.year)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final resenas = docs
              .where(
                (d) =>
                    (d.data()! as Map<String, dynamic>).safeString('tipo') ==
                    'resena',
              )
              .length;
          final refs = docs
              .where(
                (d) =>
                    (d.data()! as Map<String, dynamic>).safeString('tipo') ==
                    'referencia',
              )
              .length;
          final grupales = docs
              .where(
                (d) =>
                    (d.data()! as Map<String, dynamic>).safeString('tipo') ==
                    'grupal',
              )
              .length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.leaderboard, color: Color(0xFF7B1FA2)),
                  SizedBox(width: 8),
                  Text(
                    'TU RENDIMIENTO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.2,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _mesLabel(now.month, now.year),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _bigStat('⭐', '$resenas', 'Reseñas'),
                  _bigStat('🔗', '$refs', 'Referencias'),
                  _bigStat('🏋️', '$grupales/4', 'Grupales'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _mesLabel(int mes, int anio) {
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${meses[mes - 1]} $anio';
  }

  Widget _bigStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}
