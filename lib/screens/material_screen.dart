import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'video_player_screen.dart'; 
import '../widgets/salufit_scaffold.dart'; // <--- IMPORT NUEVO

class MaterialScreen extends StatelessWidget {
  final String userId;

  const MaterialScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return SalufitScaffold( // <--- CAMBIO A WIDGET CON FONDO
      appBar: AppBar(
        title: const Text("Mis Ejercicios", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
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
      debugPrint("Error prefs: $e");
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
       debugPrint("Error guardando: $e");
    }
  }

  Future<QuerySnapshot> _fetchExerciseByOrder(String exerciseIdFromAssignment) {
    int ordenBuscado = int.tryParse(exerciseIdFromAssignment) ?? -1;
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
    
    String a = area.toLowerCase();
    if (a.contains('fuerza') || a.contains('tono')) return {'colors': [const Color(0xFFD32F2F), const Color(0xFFE57373)], 'icon': Icons.fitness_center, 'textColor': Colors.white};
    if (a.contains('movilidad') || a.contains('estiramiento')) return {'colors': [const Color(0xFF1976D2), const Color(0xFF64B5F6)], 'icon': Icons.accessibility_new, 'textColor': Colors.white};
    if (a.contains('cardio')) return {'colors': [const Color(0xFFF57C00), const Color(0xFFFFB74D)], 'icon': Icons.directions_run, 'textColor': Colors.white};
    
    return {'colors': [const Color(0xFF009688), const Color(0xFF4DB6AC)], 'icon': Icons.play_circle_filled, 'textColor': Colors.white};
  }

  @override
  Widget build(BuildContext context) {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return const Center(child: Text("Error sesión"));

    Query query = FirebaseFirestore.instance.collection('exercise_assignments');
    if (userEmail != null) {
      query = query.where('userEmail', isEqualTo: userEmail);
    } else {
      query = query.where('userId', isEqualTo: widget.currentUserId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('fechaAsignacion', descending: true).snapshots(),
      builder: (context, snapshot) {
        
        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SelectableText("Error Material: ${snapshot.error}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
          ));
        }

        if (snapshot.connectionState == ConnectionState.waiting || _isLoadingPrefs) {
          return const Center(child: CircularProgressIndicator());
        }
        
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.video_library_outlined, size: 60, color: Colors.grey), SizedBox(height: 10), Text("Sin ejercicios asignados")]));
        }

        Set<String> uniqueInstructions = {};
        for (var doc in docs) {
          var data = doc.data() as Map<String, dynamic>;
          String instr = (data['instrucciones'] ?? "").toString().trim();
          if (instr.isNotEmpty && instr != "Sin instrucciones específicas.") {
            uniqueInstructions.add(instr);
          }
        }

        int total = docs.length;
        int completed = _completedToday.length;
        if (completed > total) completed = total; 
        double progress = total > 0 ? completed / total : 0.0;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tu objetivo diario", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("$completed / $total", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade100,
                      color: completed == total ? Colors.green : Colors.teal,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  if (uniqueInstructions.isNotEmpty) ...[
                    const Text("📝 Pauta General:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: uniqueInstructions.map((instr) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(child: Text(instr, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ] else 
                    const Text("Sigue las indicaciones del video.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                separatorBuilder: (c, i) => const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  var assignmentDoc = docs[index];
                  var data = assignmentDoc.data() as Map<String, dynamic>;
                  String exerciseCode = data['exerciseId'].toString();
                  String assignmentId = assignmentDoc.id;
                  bool isDone = _completedToday.contains(assignmentId);

                  return FutureBuilder<QuerySnapshot>(
                    future: _fetchExerciseByOrder(exerciseCode),
                    builder: (context, videoSnapshot) {
                      if (!videoSnapshot.hasData || videoSnapshot.data!.docs.isEmpty) return const SizedBox();

                      var videoDoc = videoSnapshot.data!.docs.first;
                      var videoData = videoDoc.data() as Map<String, dynamic>;
                      
                      String titulo = videoData['nombre'] ?? "Ejercicio";
                      String area = videoData['area'] ?? "General";
                      String urlVideo = videoData['urlVideo'] ?? "";

                      var visual = _getCardVisuals(area, isDone);

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
                              : [BoxShadow(color: (visual['colors'][0] as Color).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -10,
                                bottom: -10,
                                child: Icon(visual['icon'], size: 100, color: Colors.white.withOpacity(0.15)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.25),
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
                                          Text(area.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
    );
  }
}