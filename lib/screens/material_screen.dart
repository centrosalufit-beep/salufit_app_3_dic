import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'video_player_screen.dart'; 
import '../widgets/salufit_scaffold.dart'; 

class MaterialScreen extends StatelessWidget {
  final String userId;

  const MaterialScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return SalufitScaffold(
      // SIN APPBAR CLÁSICO
      body: _MaterialListBody(currentUserId: userId),
    );
  }
}

class _MaterialListBody extends StatefulWidget {
  final String currentUserId;
  const _MaterialListBody({required this.currentUserId});

  @override
  State<_MaterialListBody> createState() => _MaterialListBodyState();
}

class _MaterialListBodyState extends State<_MaterialListBody> {
  Set<String> _completedToday = {};
  bool _isLoadingPrefs = true;
  
  // COLOR CORPORATIVO
  final Color salufitTeal = const Color(0xFF009688);

  @override
  void initState() {
    super.initState();
    _loadDailyProgress();
  }

  Future<void> _loadDailyProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw 'Timeout',
      );
      
      final String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final String? lastSavedDate = prefs.getString('material_last_date');

      if (lastSavedDate != todayKey) {
        await prefs.setString('material_last_date', todayKey);
        await prefs.setStringList('material_completed_ids', []);
        if (mounted) setState(() { _completedToday = {}; });
      } else {
        final List<String> saved = prefs.getStringList('material_completed_ids') ?? [];
        if (mounted) setState(() { _completedToday = saved.toSet(); });
      }
    } catch (e) {
      debugPrint('Error prefs: $e');
    } finally {
      if (mounted) setState(() { _isLoadingPrefs = false; });
    }
  }

  Future<void> _markAsDone(String assignmentId) async {
    if (_completedToday.contains(assignmentId)) return;

    setState(() {
      _completedToday.add(assignmentId);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('material_completed_ids', _completedToday.toList());
    } catch (e) {
       debugPrint('Error guardando: $e');
    }
  }

  Future<QuerySnapshot> _fetchExerciseByOrder(String exerciseIdFromAssignment) {
    final int ordenBuscado = int.tryParse(exerciseIdFromAssignment) ?? -1;
    return FirebaseFirestore.instance
        .collection('exercises')
        .where('orden', isEqualTo: ordenBuscado)
        .limit(1)
        .get();
  }

  Map<String, dynamic> _getCardVisuals(String area, bool isDone) {
    if (isDone) {
      return {
        'colors': [Colors.grey.shade300, Colors.grey.shade400],
        'icon': Icons.check_circle,
        'textColor': Colors.grey.shade600
      };
    }
    
    final String a = area.toLowerCase();
    if (a.contains('fuerza') || a.contains('tono')) {
      return {'colors': [const Color(0xFFD32F2F), const Color(0xFFE57373)], 'icon': Icons.fitness_center, 'textColor': Colors.white};
    }
    if (a.contains('movilidad') || a.contains('estiramiento')) {
      return {'colors': [const Color(0xFF1976D2), const Color(0xFF64B5F6)], 'icon': Icons.accessibility_new, 'textColor': Colors.white};
    }
    if (a.contains('cardio')) {
      return {'colors': [const Color(0xFFF57C00), const Color(0xFFFFB74D)], 'icon': Icons.directions_run, 'textColor': Colors.white};
    }
    
    return {'colors': [const Color(0xFF009688), const Color(0xFF4DB6AC)], 'icon': Icons.play_circle_filled, 'textColor': Colors.white};
  }

  @override
  Widget build(BuildContext context) {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return const Center(child: Text('Error sesión'));

    // Optimizamos la query eliminando la redundancia
    // Si llegamos aquí, userEmail NO es nulo.
    final Query query = FirebaseFirestore.instance
        .collection('exercise_assignments')
        .where('userEmail', isEqualTo: userEmail);

    return SafeArea(
      child: Column(
        children: [
           // --- CABECERA UNIFICADA ---
           Padding(
             padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
             child: Row(
               children: [
                 Image.asset(
                    'assets/logo_salufit.png', 
                    width: 60, 
                    fit: BoxFit.contain,
                    errorBuilder: (c,e,s) => Icon(Icons.fitness_center, size: 60, color: salufitTeal),
                  ),
                 const SizedBox(width: 15),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         'MIS EJERCICIOS', 
                         style: TextStyle(
                           fontSize: 24, 
                           fontWeight: FontWeight.w900, 
                           color: salufitTeal,
                           fontFamily: 'serif',
                           letterSpacing: 2.0,
                           height: 1.0,
                           shadows: [Shadow(offset: const Offset(1, 1), color: Colors.black.withValues(alpha: 0.1), blurRadius: 0)]
                         ),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       ),
                       const SizedBox(height: 4),
                       const Text('Tu plan personalizado', style: TextStyle(color: Colors.grey, fontSize: 14)),
                     ],
                   ),
                 ),
               ],
             ),
           ),

           Expanded(
             child: StreamBuilder<QuerySnapshot>(
              stream: query.orderBy('fechaAsignacion', descending: true).snapshots(),
              builder: (context, snapshot) {
                
                if (snapshot.hasError) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SelectableText('Error Material: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  ));
                }

                if (snapshot.connectionState == ConnectionState.waiting || _isLoadingPrefs) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library_outlined, size: 60, color: Colors.grey), SizedBox(height: 10), Text('Sin ejercicios asignados')]));
                }

                final Set<String> uniqueInstructions = {};
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String instr = (data['instrucciones'] ?? '').toString().trim();
                  if (instr.isNotEmpty && instr != 'Sin instrucciones específicas.') {
                    uniqueInstructions.add(instr);
                  }
                }

                final int total = docs.length;
                int completed = _completedToday.length;
                if (completed > total) completed = total; 
                final double progress = total > 0 ? completed / total : 0.0;
                final int percentage = (progress * 100).toInt();

                return Column(
                  children: [
                    // --- TARJETA DE PROGRESO ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [salufitTeal, Colors.teal.shade800],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [BoxShadow(color: salufitTeal.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 5))]
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Lado Izquierdo: Textos
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.track_changes, color: Colors.white70, size: 16),
                                          SizedBox(width: 5),
                                          Text('OBJETIVO DIARIO', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text('$completed', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                                          Text('/$total', style: const TextStyle(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const Text('Ejercicios completados', style: TextStyle(color: Colors.white, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                
                                // Lado Derecho: Indicador Circular
                                SizedBox(
                                  height: 70,
                                  width: 70,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CircularProgressIndicator(
                                        value: progress,
                                        strokeWidth: 8,
                                        backgroundColor: Colors.white24,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeCap: StrokeCap.round,
                                      ),
                                      Center(child: Text('$percentage%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Sección de Instrucciones
                            if (uniqueInstructions.isNotEmpty) 
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.white24)
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.white, size: 16),
                                        SizedBox(width: 5),
                                        Text('PAUTA DEL PROFESIONAL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...uniqueInstructions.map((instr) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                          Expanded(child: Text(instr, style: const TextStyle(fontSize: 13, color: Colors.white))),
                                        ],
                                      ),
                                    )),
                                  ],
                                ),
                              )
                            else 
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                                child: const Text('Sigue las indicaciones del video.', style: TextStyle(fontSize: 12, color: Colors.white70), textAlign: TextAlign.center),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // LISTA DE EJERCICIOS
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        itemCount: docs.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 15),
                        itemBuilder: (context, index) {
                          final assignmentDoc = docs[index];
                          final data = assignmentDoc.data() as Map<String, dynamic>;
                          final String exerciseCode = data['exerciseId'].toString();
                          final String assignmentId = assignmentDoc.id;
                          final bool isDone = _completedToday.contains(assignmentId);

                          return FutureBuilder<QuerySnapshot>(
                            future: _fetchExerciseByOrder(exerciseCode),
                            builder: (context, videoSnapshot) {
                              if (!videoSnapshot.hasData || videoSnapshot.data!.docs.isEmpty) return const SizedBox();

                              final videoDoc = videoSnapshot.data!.docs.first;
                              final videoData = videoDoc.data() as Map<String, dynamic>;
                              
                              final String titulo = videoData['nombre'] ?? 'Ejercicio';
                              final String area = videoData['area'] ?? 'General';
                              final String urlVideo = videoData['urlVideo'] ?? '';

                              final visual = _getCardVisuals(area, isDone);

                              return InkWell(
                                onTap: () async {
                                  if (urlVideo.isNotEmpty) {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VideoPlayerScreen(
                                          videoUrl: urlVideo,
                                          title: titulo,
                                          assignmentId: assignmentId,
                                        ),
                                      ),
                                    );
                                    _markAsDone(assignmentId);
                                  }
                                },
                                child: Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: visual['colors'],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: isDone 
                                      ? [] 
                                      : [BoxShadow(color: (visual['colors'][0] as Color).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        right: -10,
                                        bottom: -10,
                                        child: Icon(visual['icon'], size: 100, color: Colors.white.withValues(alpha: 0.15)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.25),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(isDone ? Icons.check : Icons.play_arrow, color: Colors.white, size: 24),
                                            ),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(area.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                                  const SizedBox(height: 4),
                                                  Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
           ),
        ],
      ),
    );
  }
}