import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/professional/presentation/professional_tasks_screen.dart';

class ProfessionalDesktopDashboardScreen extends StatelessWidget {
  const ProfessionalDesktopDashboardScreen({
    required this.userId,
    required this.userRole,
    super.key,
  });

  final String userId;
  final String userRole;

  @override
  Widget build(BuildContext context) {
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
              _JornadaCardDesktop(userId: userId),
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

class _JornadaCardDesktop extends StatelessWidget {
  const _JornadaCardDesktop({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('timeClockRecords')
          .where('userId', isEqualTo: userId)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        QueryDocumentSnapshot? lastDoc;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final sorted = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final tsA = ((a.data()! as Map<String, dynamic>)['timestamp']
                          as Timestamp?)
                      ?.millisecondsSinceEpoch ??
                  0;
              final tsB = ((b.data()! as Map<String, dynamic>)['timestamp']
                          as Timestamp?)
                      ?.millisecondsSinceEpoch ??
                  0;
              return tsB.compareTo(tsA);
            });
          lastDoc = sorted.first;
        }
        final isClockedIn = lastDoc != null &&
            (lastDoc.data()! as Map<String, dynamic>)['type'] == 'IN';
        final lastTime = lastDoc != null
            ? ((lastDoc.data()! as Map<String, dynamic>)['timestamp']
                    as Timestamp?)
                ?.toDate()
            : null;

        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isClockedIn
                  ? [const Color(0xFF009688), const Color(0xFF4DB6AC)]
                  : [const Color(0xFF455A64), const Color(0xFF78909C)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isClockedIn
                        ? const Color(0xFF009688)
                        : const Color(0xFF455A64))
                    .withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isClockedIn ? Icons.timer : Icons.timer_off,
                color: Colors.white,
                size: 56,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isClockedIn ? 'JORNADA ACTIVA' : 'FUERA DE JORNADA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lastTime != null
                          ? (isClockedIn
                              ? 'Entrada: ${_fmt(lastTime)}'
                              : 'Última salida: ${_fmt(lastTime)}')
                          : 'Sin fichajes registrados',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Gestiona tu fichaje desde el panel lateral izquierdo.',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _PendingTasksPanel extends StatelessWidget {
  const _PendingTasksPanel({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
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
        stream: FirebaseFirestore.instance
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

class _MiniCrmPanel extends StatelessWidget {
  const _MiniCrmPanel({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
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
        stream: FirebaseFirestore.instance
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
