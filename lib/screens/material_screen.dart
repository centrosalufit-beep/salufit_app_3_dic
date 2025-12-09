import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'video_player_screen.dart'; 
import '../widgets/salufit_scaffold.dart'; 

class MaterialScreen extends StatelessWidget {
  final String userId;
  final bool embedMode; 

  const MaterialScreen({
    super.key, 
    required this.userId,
    this.embedMode = false, 
  });

  @override
  Widget build(BuildContext context) {
    if (embedMode) {
      return _MaterialListBody(currentUserId: userId, embedMode: true);
    }
    return SalufitScaffold(
      body: _MaterialListBody(currentUserId: userId, embedMode: false),
    );
  }
}

class _MaterialListBody extends StatefulWidget {
  final String currentUserId;
  final bool embedMode;
  const _MaterialListBody({required this.currentUserId, required this.embedMode});

  @override
  State<_MaterialListBody> createState() => _MaterialListBodyState();
}

class _MaterialListBodyState extends State<_MaterialListBody> {
  Set<String> _completedToday = {};
  bool _isLoadingPrefs = true;
  String _userRole = 'cliente'; 
  bool _checkingRole = true;
  
  final Color salufitTeal = const Color(0xFF009688);

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadDailyProgress();
  }

  Future<void> _checkUserRole() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.currentUserId).get();
      
      if (doc.exists && mounted) {
        setState(() {
          _userRole = (doc.data()?['rol'] ?? 'cliente').toString().toLowerCase();
          _checkingRole = false;
        });
      } else {
        if (mounted) setState(() => _checkingRole = false);
      }
    } catch (e) {
      debugPrint('Error verificando rol (se asume cliente): $e');
      if (mounted) setState(() => _checkingRole = false);
    }
  }

  // --- LÓGICA DE RESET DIARIO (00:00) ---
  Future<void> _loadDailyProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final String? lastSavedDate = prefs.getString('material_last_date');

      // Si la fecha guardada es diferente a hoy, reseteamos a 0
      if (lastSavedDate != todayKey) {
        await prefs.setString('material_last_date', todayKey);
        await prefs.setStringList('material_completed_ids', []);
        if (mounted) setState(() { _completedToday = {}; });
      } else {
        // Si es el mismo día, cargamos lo que llevábamos
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

  Map<String, dynamic> _getCardVisuals(String area, bool isDone) {
    if (isDone) {
      return {
        'colors': [Colors.grey.shade300, Colors.grey.shade400],
        'icon': Icons.check_circle,
        'textColor': Colors.grey.shade600,
        'opacity': 0.5 
      };
    }
    
    final String a = area.toLowerCase();
    if (a.contains('fuerza') || a.contains('tono') || a.contains('entrenamiento')) {
      return {'colors': [const Color(0xFFD32F2F), const Color(0xFFE57373)], 'icon': Icons.fitness_center, 'textColor': Colors.white, 'opacity': 1.0};
    }
    if (a.contains('movilidad') || a.contains('estiramiento') || a.contains('fisioterapia')) {
      return {'colors': [const Color(0xFF1976D2), const Color(0xFF64B5F6)], 'icon': Icons.accessibility_new, 'textColor': Colors.white, 'opacity': 1.0};
    }
    if (a.contains('cardio')) {
      return {'colors': [const Color(0xFFF57C00), const Color(0xFFFFB74D)], 'icon': Icons.directions_run, 'textColor': Colors.white, 'opacity': 1.0};
    }
    
    return {'colors': [const Color(0xFF009688), const Color(0xFF4DB6AC)], 'icon': Icons.play_circle_filled, 'textColor': Colors.white, 'opacity': 1.0};
  }

  // --- WIDGET TARJETA DISCOVER CON GAMIFICACIÓN E INSTRUCCIONES ---
  Widget _buildProgressHeader(int completed, int total) {
    final double progress = total == 0 ? 0 : completed / total;
    
    const String instruccion = 'Vas a hacer cada ejercicio un total de 2 veces de 1 minuto por cada vez con 40 segundos de descanso. En cada minuto es necesario que cuentes cuántas repeticiones haces e intentes hacer una más.';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [salufitTeal, salufitTeal.withValues(alpha: 0.7)], // FIX: withValues
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: salufitTeal.withValues(alpha: 0.3), // FIX: withValues
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TU OBJETIVO DIARIO',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
                child: Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$completed/$total',
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1.0),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('ejercicios completados', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Barra de Progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.black26,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 15),
          // CAJA DE INSTRUCCIONES
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15), // FIX: withValues
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)), // FIX: withValues
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    instruccion,
                    style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // VISTA PARA CLIENTES
  // ==============================================================
  Widget _buildClientView(String userEmail) {
    // Apuntamos a la colección raíz 'exercise_assignments'
    final Query query = FirebaseFirestore.instance
        .collection('exercise_assignments')
        .where('userEmail', isEqualTo: userEmail);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(), 
      builder: (context, snapshot) {
        if (snapshot.hasError) {
           return Center(child: Padding(
             padding: const EdgeInsets.all(20.0),
             child: Text('Error cargando ejercicios: ${snapshot.error}', style: TextStyle(color: Colors.grey[600])),
           ));
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final docs = snapshot.data?.docs ?? [];
        
        // --- CÁLCULO DE CONTADORES ---
        final int totalExercises = docs.length;
        final int completedCount = docs.where((doc) => _completedToday.contains(doc.id)).length;

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Icon(Icons.video_library_outlined, size: 60, color: Colors.grey), 
                SizedBox(height: 10), 
                Text('No tienes ejercicios asignados aún')
              ]
            )
          );
        }
        
        // Ordenación por fecha (descendente)
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          
          final dateA = (dataA['fechaAsignacion'] is Timestamp) 
              ? (dataA['fechaAsignacion'] as Timestamp).toDate() 
              : DateTime.tryParse(dataA['fechaAsignacion'].toString()) ?? DateTime(1970);
              
          final dateB = (dataB['fechaAsignacion'] is Timestamp) 
              ? (dataB['fechaAsignacion'] as Timestamp).toDate() 
              : DateTime.tryParse(dataB['fechaAsignacion'].toString()) ?? DateTime(1970);

          return dateB.compareTo(dateA);
        });
        
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          children: [
            // 1. HEADER
            _buildProgressHeader(completedCount, totalExercises),

            // 2. LISTA
            ...docs.map((assignmentDoc) {
              final data = assignmentDoc.data() as Map<String, dynamic>;
              final String assignmentId = assignmentDoc.id;
              final bool isDone = _completedToday.contains(assignmentId);

              // Datos directos del documento de asignación
              final String titulo = data['nombre'] ?? 'Ejercicio';
              final String urlVideo = data['urlVideo'] ?? '';
              // Si no hay familia definida, asumimos Entrenamiento (Rojo)
              final String area = data['familia'] ?? data['area'] ?? 'Entrenamiento';

              final visual = _getCardVisuals(area, isDone);

              return Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: _buildExerciseCard(
                  titulo: titulo,
                  area: area,
                  visual: visual,
                  isDone: isDone,
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
                      // AL VOLVER
                      _markAsDone(assignmentId);
                    } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Este ejercicio no tiene video adjunto'))
                        );
                    }
                  }
                ),
              );
            })
          ],
        );
      },
    );
  }

  // ==============================================================
  // VISTA PARA ADMIN/PROFESIONAL
  // ==============================================================
  Widget _buildAdminView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('exercises').orderBy('orden').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error cargando librería'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Librería vacía'));

        final docs = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          itemCount: docs.length,
          separatorBuilder: (c, i) => const SizedBox(height: 15),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            final String titulo = data['nombre'] ?? 'Sin nombre';
            final String area = data['familia'] ?? 'General';
            final String urlVideo = data['urlVideo'] ?? '';
            final int orden = data['orden'] ?? 0;
            
            final visual = _getCardVisuals(area, false); 

            return _buildExerciseCard(
              titulo: '#$orden - $titulo', 
              area: area,
              visual: visual,
              isDone: false,
              onTap: () {
                if (urlVideo.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(
                        videoUrl: urlVideo,
                        title: titulo,
                        assignmentId: '', 
                      ),
                    ),
                  );
                }
              }
            );
          },
        );
      },
    );
  }

  Widget _buildExerciseCard({
    required String titulo, 
    required String area, 
    required Map<String, dynamic> visual, 
    required bool isDone, 
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: visual['opacity'] ?? 1.0, 
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
              : [BoxShadow(color: (visual['colors'][0] as Color).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))], // FIX: withValues
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(visual['icon'], size: 100, color: Colors.white.withValues(alpha: 0.15)), // FIX: withValues
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25), // FIX: withValues
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
                          Text(area.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)), // FIX: withValues
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return const Center(child: Text('Error sesión'));

    return SafeArea(
      top: !widget.embedMode,
      bottom: false,
      child: Column(
        children: [
           if (!widget.embedMode)
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
                             shadows: [Shadow(offset: const Offset(1, 1), color: Colors.black.withValues(alpha: 0.1), blurRadius: 0)] // FIX: withValues
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
             child: (_checkingRole || _isLoadingPrefs) 
                ? const Center(child: CircularProgressIndicator())
                : (_userRole == 'admin' || _userRole == 'profesional')
                    ? _buildAdminView() 
                    : _buildClientView(userEmail) 
           ),
        ],
      ),
    );
  }
}