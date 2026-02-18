import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/patient_record/presentation/video_player_screen.dart';
import 'package:salufit_app/features/patient_record/providers/material_providers.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ClientMaterialScreen extends ConsumerWidget {
  const ClientMaterialScreen({required this.userId, this.embedMode = false, super.key});
  final String userId;
  final bool embedMode;
  static const Color salufitTeal = Color(0xFF009688);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(myAssignmentsProvider);
    final completedSet = ref.watch(dailyProgressProvider);
    
    final List<Map<String, dynamic>> docs = assignmentsAsync.value ?? [];
    final int total = docs.length;
    final int done = docs.where((d) => completedSet.contains(d['id']?.toString())).length;
    final double progress = total == 0 ? 0.0 : (done / total);

    return SalufitScaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressCard(done, total, progress),
            Expanded(
              child: assignmentsAsync.when(
                data: (docsList) => docsList.isEmpty 
                  ? const Center(child: Text('No tienes ejercicios asignados todavía', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                      itemCount: docsList.length,
                      itemBuilder: (context, index) {
                        final data = docsList[index];
                        final String safeId = data['id']?.toString() ?? '';
                        return _CompactExerciseCard(
                          assignmentId: safeId,
                          titulo: data.safeString('nombre', defaultValue: 'Ejercicio'),
                          area: data.safeString('familia', defaultValue: 'Entrenamiento'),
                          urlVideo: data.safeString('urlVideo', defaultValue: data.safeString('videoUrl')),
                          isDone: completedSet.contains(safeId),
                        );
                      },
                    ),
                loading: () => const Center(child: CircularProgressIndicator(color: salufitTeal)),
                error: (e, _) => const Center(child: Text('Error al cargar material')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => const Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
    child: Text('TU MATERIAL', style: TextStyle(fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.w900, color: salufitTeal)),
  );

  Widget _buildProgressCard(int done, int total, double progress) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Tarjeta Principal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [salufitTeal, Color(0xFF4DB6AC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: salufitTeal.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('OBJETIVO DIARIO', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                const SizedBox(height: 5),
                Text('$done/$total', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                const Text('ejercicios completados', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress, 
                    backgroundColor: Colors.white.withValues(alpha: 0.2), 
                    valueColor: const AlwaysStoppedAnimation(Colors.white), 
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          // Badge Circular de Actividad Mensual (Inyectado)
          Positioned(
            top: 15,
            right: 15,
            child: _buildActivityBadge("12", "HITS"),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBadge(String value, String label) {
    return Container(
      width: 65,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(color: Color(0xFFFF9800), fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

}

class _CompactExerciseCard extends ConsumerWidget {
  const _CompactExerciseCard({required this.assignmentId, required this.titulo, required this.area, required this.urlVideo, required this.isDone});
  final String assignmentId;
  final String titulo;
  final String area;
  final String urlVideo;
  final bool isDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color color = area.toLowerCase().contains('fuerza') ? const Color(0xFFD32F2F) : const Color(0xFF1976D2);
    
    return Container(
      height: 75,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          if (urlVideo.isEmpty) return;
          HapticFeedback.lightImpact();
          await Navigator.push<void>(
            context, 
            MaterialPageRoute<void>(
              builder: (_) => VideoPlayerScreen(videoUrl: urlVideo, title: titulo, assignmentId: assignmentId)
            )
          );
          ref.read(dailyProgressProvider.notifier).markAsDone(assignmentId);
        },
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12), 
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Icon(isDone ? Icons.check_circle : Icons.play_circle_outline, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(area.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900)),
                      Text(titulo.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
