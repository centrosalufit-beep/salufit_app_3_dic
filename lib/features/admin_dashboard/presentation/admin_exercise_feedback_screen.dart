import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

/// Panel admin con el ranking de ejercicios por número de DISLIKES descendente.
///
/// Lee la colección `exerciseStats` que el reproductor de vídeo del cliente
/// va alimentando con counters por ejercicio (`likes`, `dislikes`, `difFacil`,
/// `difMedio`, `difDificil`). Permite identificar rápidamente qué ejercicios
/// no gustan o resultan demasiado difíciles de forma transversal a todos los
/// pacientes.
class AdminExerciseFeedbackScreen extends ConsumerWidget {
  const AdminExerciseFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref
        .watch(firebaseFirestoreProvider)
        .collection('exerciseStats')
        .orderBy('dislikes', descending: true)
        .limit(200)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Feedback de ejercicios'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF009688)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error cargando feedback:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          final filtered = docs
              .where((d) => (d.data().safeInt('dislikes')) > 0)
              .toList();
          if (filtered.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'Sin "dislikes" registrados.\nLos votos negativos aparecerán aquí ordenados por frecuencia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ),
            );
          }
          return Column(
            children: [
              _Header(total: filtered.length),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    return _StatRow(
                      rank: index + 1,
                      exerciseId: doc.id,
                      exerciseName: data.safeString(
                        'exerciseName',
                        defaultValue: 'Ejercicio sin nombre',
                      ),
                      likes: data.safeInt('likes'),
                      dislikes: data.safeInt('dislikes'),
                      difDificil: data.safeInt('difDificil'),
                      difMedio: data.safeInt('difMedio'),
                      difFacil: data.safeInt('difFacil'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: Colors.white.withValues(alpha: 0.95),
      child: Row(
        children: [
          const Icon(Icons.thumbs_up_down_outlined,
              color: Color(0xFF009688), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ejercicios con dislikes (ordenados por frecuencia)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              '$total',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.rank,
    required this.exerciseId,
    required this.exerciseName,
    required this.likes,
    required this.dislikes,
    required this.difDificil,
    required this.difMedio,
    required this.difFacil,
  });

  final int rank;
  final String exerciseId;
  final String exerciseName;
  final int likes;
  final int dislikes;
  final int difDificil;
  final int difMedio;
  final int difFacil;

  @override
  Widget build(BuildContext context) {
    final total = likes + dislikes;
    final ratio = total == 0 ? 0.0 : likes / total;
    final tone = dislikes >= 5
        ? Colors.red.shade50
        : dislikes >= 2
            ? Colors.orange.shade50
            : Colors.white;
    final border = dislikes >= 5
        ? Colors.red.shade200
        : dislikes >= 2
            ? Colors.orange.shade200
            : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'ID: $exerciseId',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _ChipCounter(
                icon: Icons.thumb_down,
                value: dislikes,
                color: Colors.red,
                emphasis: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ChipCounter(
                icon: Icons.thumb_up,
                value: likes,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _PillCounter(
                label: '🟢',
                value: difFacil,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 6),
              _PillCounter(
                label: '🟡',
                value: difMedio,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 6),
              _PillCounter(
                label: '🔴',
                value: difDificil,
                color: Colors.red.shade700,
              ),
              const Spacer(),
              if (total > 0)
                Text(
                  '${(ratio * 100).round()}% +',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipCounter extends StatelessWidget {
  const _ChipCounter({
    required this.icon,
    required this.value,
    required this.color,
    this.emphasis = false,
  });

  final IconData icon;
  final int value;
  final Color color;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: emphasis ? 12 : 10,
        vertical: emphasis ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: emphasis ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: emphasis ? 18 : 14, color: color),
          const SizedBox(width: 5),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: emphasis ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillCounter extends StatelessWidget {
  const _PillCounter({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
