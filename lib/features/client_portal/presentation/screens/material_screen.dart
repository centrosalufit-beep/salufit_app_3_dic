// lib/features/patient_record/presentation/material_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';
import 'package:salufit_app/features/patient_record/presentation/video_player_screen.dart';
import 'package:salufit_app/features/patient_record/providers/material_providers.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';
import 'package:skeletonizer/skeletonizer.dart';

// -----------------------------------------------------------------------------
// 1. WIDGET PRINCIPAL
// -----------------------------------------------------------------------------
class MaterialScreen extends StatelessWidget {
  const MaterialScreen({
    required this.userId,
    super.key,
    this.embedMode = false,
  });

  final String userId;
  final bool embedMode;

  static const Color salufitTeal = Color(0xFF009688);

  @override
  Widget build(BuildContext context) {
    if (embedMode) {
      return const _MaterialListBody();
    }

    return SalufitScaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // --- HEADER UNIFICADO ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: <Widget>[
                  Image.asset(
                    'assets/logo_salufit.png',
                    width: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.fitness_center,
                      size: 50,
                      color: salufitTeal,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'TU MATERIAL',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: salufitTeal,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Para completar tu tratamiento',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Contenido Principal
            const Expanded(child: _MaterialListBody()),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. BODY CON LÓGICA DE ROLES
// -----------------------------------------------------------------------------
class _MaterialListBody extends ConsumerWidget {
  const _MaterialListBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error cargando perfil')),
      data: (DocumentSnapshot<Object?> userDoc) {
        final data = userDoc.data() as Map<String, dynamic>?;
        final role = data.safeString('rol', defaultValue: 'cliente');

        final isAdminOrStaff =
            role == 'admin' || role == 'profesional' || role == 'administrador';

        if (isAdminOrStaff) {
          return const Center(
            child: Text(
              'Vista de Staff: Usa el panel de administración para asignar ejercicios.',
            ),
          );
        }

        return const _ClientExerciseList();
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 3. LISTA DE EJERCICIOS
// -----------------------------------------------------------------------------
class _ClientExerciseList extends ConsumerWidget {
  const _ClientExerciseList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(myAssignmentsProvider);
    final completedSet = ref.watch(dailyProgressProvider);
    const salufitTeal = Color(0xFF009688);

    final isLoading = assignmentsAsync.isLoading;
    final docs = assignmentsAsync.valueOrNull ?? <DocumentSnapshot<Object?>>[];

    final totalExercises = docs.length;
    final completedCount = isLoading
        ? 0
        : docs.where((doc) => completedSet.contains(doc.id)).length;

    final progress =
        totalExercises == 0 ? 0.0 : (completedCount / totalExercises);

    return Skeletonizer(
      enabled: isLoading,
      child: CustomScrollView(
        slivers: <Widget>[
          if (!isLoading && docs.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.video_library_outlined,
                      size: 60,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 10),
                    Text('No tienes ejercicios asignados aún'),
                  ],
                ),
              ),
            )
          else ...<Widget>[
            // TARJETA DE PROGRESO
            SliverToBoxAdapter(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      salufitTeal,
                      salufitTeal.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: salufitTeal.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'TU OBJETIVO DIARIO',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          isLoading
                              ? '--/--'
                              : '$completedCount/$totalExercises',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Text(
                            'ejercicios completados',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.black26,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // LISTA
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
              sliver: SliverList.builder(
                itemCount: isLoading ? 6 : docs.length,
                itemBuilder: (BuildContext context, int index) {
                  if (isLoading) {
                    return const _ExerciseCard(
                      assignmentId: 'dummy',
                      titulo: 'Cargando ejercicio...',
                      area: 'Entrenamiento',
                      urlVideo: '',
                      isDone: false,
                      isLoading: true,
                    );
                  }

                  final assignmentDoc = docs[index];
                  final data = assignmentDoc.data()! as Map<String, dynamic>;
                  final assignmentId = assignmentDoc.id;
                  final isDone = completedSet.contains(assignmentId);

                  // CORRECCIÓN: Usamos .safeString()
                  final titulo =
                      data.safeString('nombre', defaultValue: 'Ejercicio');

                  var urlVideo = data.safeString('urlVideo');
                  if (urlVideo.isEmpty) {
                    urlVideo = data.safeString('videoUrl');
                  }

                  final originalExerciseId = data.containsKey('exerciseId')
                      ? data.safeString('exerciseId')
                      : null;

                  final area = data.safeString(
                    'familia',
                    defaultValue:
                        data.safeString('area', defaultValue: 'Entrenamiento'),
                  );

                  final needsDetails =
                      urlVideo.isEmpty || titulo == 'Ejercicio';

                  return needsDetails
                      ? _SmartExerciseCard(
                          assignmentId: assignmentId,
                          originalId: originalExerciseId,
                          tituloBase: titulo,
                          area: area,
                          urlVideoBase: urlVideo,
                          isDone: isDone,
                        )
                      : _ExerciseCard(
                          assignmentId: assignmentId,
                          titulo: titulo,
                          area: area,
                          urlVideo: urlVideo,
                          isDone: isDone,
                        );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. SMART CARD (Helpers)
// -----------------------------------------------------------------------------
class _SmartExerciseCard extends ConsumerWidget {
  const _SmartExerciseCard({
    required this.assignmentId,
    required this.originalId,
    required this.tituloBase,
    required this.area,
    required this.urlVideoBase,
    required this.isDone,
  });

  final String assignmentId;
  final String? originalId;
  final String tituloBase;
  final String area;
  final String urlVideoBase;
  final bool isDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(exerciseDetailsProvider(originalId));

    return detailsAsync.when(
      data: (Map<String, String?> details) {
        final titulo = details['titulo'] ?? tituloBase;
        final url = details['video'] ?? urlVideoBase;
        return _ExerciseCard(
          assignmentId: assignmentId,
          titulo: titulo,
          area: area,
          urlVideo: url,
          isDone: isDone,
        );
      },
      loading: () => _ExerciseCard(
        assignmentId: assignmentId,
        titulo: 'Cargando detalles...',
        area: area,
        urlVideo: '',
        isDone: isDone,
        isLoading: true,
      ),
      error: (_, __) => _ExerciseCard(
        assignmentId: assignmentId,
        titulo: tituloBase,
        area: area,
        urlVideo: urlVideoBase,
        isDone: isDone,
      ),
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    required this.assignmentId,
    required this.titulo,
    required this.area,
    required this.urlVideo,
    required this.isDone,
    this.isLoading = false,
  });

  final String assignmentId;
  final String titulo;
  final String area;
  final String urlVideo;
  final bool isDone;
  final bool isLoading;

  Map<String, dynamic> _getVisuals(String area, bool isDone) {
    if (isDone) {
      return <String, dynamic>{
        'colors': <Color>[Colors.grey.shade300, Colors.grey.shade400],
        'icon': Icons.check_circle,
        'opacity': 0.5,
      };
    }
    final a = area.toLowerCase();
    if (a.contains('fuerza') || a.contains('tono')) {
      return <String, dynamic>{
        'colors': <Color>[const Color(0xFFD32F2F), const Color(0xFFE57373)],
        'icon': Icons.fitness_center,
        'opacity': 1.0,
      };
    }
    if (a.contains('movilidad') || a.contains('fisioterapia')) {
      return <String, dynamic>{
        'colors': <Color>[const Color(0xFF1976D2), const Color(0xFF64B5F6)],
        'icon': Icons.accessibility_new,
        'opacity': 1.0,
      };
    }
    return <String, dynamic>{
      'colors': <Color>[const Color(0xFF009688), const Color(0xFF4DB6AC)],
      'icon': Icons.play_circle_filled,
      'opacity': 1.0,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visual = _getVisuals(area, isDone);
    final colors = visual['colors'] as List<Color>;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: (isLoading || urlVideo.isEmpty)
            ? null
            : () async {
                await HapticFeedback.lightImpact();
                if (!context.mounted) return;

                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => VideoPlayerScreen(
                      videoUrl: urlVideo,
                      title: titulo,
                      assignmentId: assignmentId,
                    ),
                  ),
                );

                if (context.mounted) {
                  await ref
                      .read(dailyProgressProvider.notifier)
                      .markAsDone(assignmentId);
                }
              },
        borderRadius: BorderRadius.circular(20),
        child: Opacity(
          opacity: visual['opacity'] as double,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDone
                  ? <BoxShadow>[]
                  : <BoxShadow>[
                      BoxShadow(
                        color: colors[0].withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    visual['icon'] as IconData,
                    size: 100,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                isDone ? Icons.check : Icons.play_arrow,
                                color: Colors.white,
                                size: 24,
                              ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              area.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              titulo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
