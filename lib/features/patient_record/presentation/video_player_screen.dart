// lib/features/patient_record/presentation/video_player_screen.dart

import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback y orientación
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    required this.videoUrl,
    required this.title,
    required this.assignmentId,
    super.key,
  });

  final String videoUrl;
  final String title;
  final String assignmentId;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  // --- CONTROLADORES DE VIDEO ---
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isError = false;
  String _errorMessage = '';
  bool _isLoadingVideo = true;

  // --- VARIABLES DE FEEDBACK ---
  bool? _leGusta;
  String? _dificultad;

  // --- VARIABLES DEL TEMPORIZADOR ---
  Timer? _workoutTimer;
  int _currentSeconds = 0;
  bool _isTimerRunning = false;
  bool _isPaused = false;
  bool _isWorking = true;
  int _currentSet = 1;

  // Configuración por defecto (editable por el usuario)
  int _cfgSets = 2;
  int _cfgWork = 60;
  int _cfgRest = 40;

  // Fallback solo si el asignment no trae URL (no debería pasar en producción).
  static const String _fallbackDemoVideoUrl =
      'https://firebasestorage.googleapis.com/v0/b/salufitnewapp.firebasestorage.app/o/1.mp4?alt=media';

  // --- TUTORIAL / ONBOARDING ---
  final GlobalKey _likeKey = GlobalKey();
  final GlobalKey _semaforoKey = GlobalKey();
  final GlobalKey _timerKey = GlobalKey();
  TutorialCoachMark? _tutorial;
  static const String _tutorialPrefsKey = 'video_player_tutorial_seen_v1';

  @override
  void initState() {
    super.initState();
    debugPrint('Iniciando reproductor para: ${widget.title}');
    _initializePlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowTutorial();
    });
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _tutorial?.finish();
    // Restaurar orientación vertical al salir por si acaso
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  // =========================================================
  // 1. INICIALIZACIÓN DEL VIDEO
  // =========================================================
  Future<void> _initializePlayer() async {
    // Usa el videoUrl que el profesional asignó al cliente.
    // Solo cae al demo si la URL llega vacía (asignment mal formado).
    final url = widget.videoUrl.trim().isEmpty
        ? _fallbackDemoVideoUrl
        : widget.videoUrl.trim();
    if (url == _fallbackDemoVideoUrl) {
      debugPrint('⚠️ videoUrl vacío en assignment ${widget.assignmentId} — usando demo');
    }

    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(url),
      );

      await _videoPlayerController!.initialize();

      if (!mounted) return;

      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: true,
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          // Evitamos que la pantalla se apague mientras entrena
          allowedScreenSleep: false,

          // Personalización UI del Player
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.teal,
            handleColor: Colors.tealAccent,
            backgroundColor: Colors.grey,
            bufferedColor: Colors.white30,
          ),

          // Placeholder mientras carga o si hay error visual
          placeholder: const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          ),

          errorBuilder: (context, errorMessage) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Error de reproducción:\n$errorMessage',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
        _isLoadingVideo = false;
      });
    } catch (e) {
      debugPrint('🔴 Error FATAL inicializando video: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = e.toString();
          _isLoadingVideo = false;
        });
      }
    }
  }

  // =========================================================
  // 2. LÓGICA DE FEEDBACK (FIRESTORE)
  // =========================================================
  Future<void> _enviarFeedback(String campo, Object valor) async {
    HapticFeedback.lightImpact(); // Feedback táctil
    final esRojo = campo == 'dificultad' && valor == 'dificil';

    final updates = <String, Object?>{
      'feedback.$campo': valor,
      'feedback.fecha': FieldValue.serverTimestamp(),
      'feedback.alerta': (campo == 'gustado' && valor == false) || esRojo,
    };

    final assignmentRef = FirebaseFirestore.instance
        .collection('exercise_assignments')
        .doc(widget.assignmentId);
    await assignmentRef.update(updates);

    setState(() {
      if (campo == 'gustado' && valor is bool) {
        _leGusta = valor;
      }
      if (campo == 'dificultad' && valor is String) {
        _dificultad = valor;
      }
    });

    // Trigger tarea para el profesional cuando el cliente marca rojo.
    if (esRojo) {
      unawaited(_crearOActualizarTareaDificultadRoja(assignmentRef));
    }
  }

  // Crea o actualiza una tarea en `internal_tasks` cuando el cliente marca
  // dificultad ROJA. Deduplica por (clientId, exerciseId) si ya existe una
  // tarea con status='pendiente'; si existe pero está 'resuelta', crea una
  // nueva (problema reapareció). Visibilidad: profesional asignador + admin.
  Future<void> _crearOActualizarTareaDificultadRoja(
    DocumentReference<Map<String, dynamic>> assignmentRef,
  ) async {
    try {
      final assignmentSnap = await assignmentRef.get();
      if (!assignmentSnap.exists) return;
      final data = assignmentSnap.data() ?? {};

      final clientId = (data['userId'] ?? data['clientId'] ?? '') as String;
      final assignedBy =
          (data['assignedBy'] ?? data['professionalId'] ?? '') as String;
      final exerciseId =
          (data['exerciseId'] ?? data['ejercicioId'] ?? widget.assignmentId)
              as String;
      final exerciseName =
          (data['nombre'] ?? data['exerciseName'] ?? widget.title) as String;

      if (clientId.isEmpty || assignedBy.isEmpty) {
        debugPrint('⚠️ Tarea NO creada: assignment sin userId o assignedBy');
        return;
      }

      final tasksCol = FirebaseFirestore.instance.collection('internal_tasks');

      // Buscar tarea pendiente existente para deduplicar.
      final existing = await tasksCol
          .where('type', isEqualTo: 'video_difficulty_red')
          .where('clientId', isEqualTo: clientId)
          .where('exerciseId', isEqualTo: exerciseId)
          .where('status', isEqualTo: 'pendiente')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        // Actualizar contador y fecha del último reporte
        await existing.docs.first.reference.update({
          'reportCount': FieldValue.increment(1),
          'lastReportAt': FieldValue.serverTimestamp(),
          'pushPending': true,
        });
      } else {
        // Crear nueva tarea
        await tasksCol.add({
          'type': 'video_difficulty_red',
          'clientId': clientId,
          'exerciseId': exerciseId,
          'exerciseName': exerciseName,
          'videoUrl': widget.videoUrl,
          'assignmentId': widget.assignmentId,
          'assignedBy': assignedBy,
          'visibleTo': [assignedBy], // admin se considera por rol, no por uid
          'status': 'pendiente',
          'reportCount': 1,
          'firstReportAt': FieldValue.serverTimestamp(),
          'lastReportAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'pushPending': true,
        });
      }
    } catch (e, st) {
      debugPrint('❌ Error creando tarea dificultad roja: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  // =========================================================
  // 2.b ONBOARDING / TUTORIAL
  // =========================================================
  Future<void> _maybeShowTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_tutorialPrefsKey) ?? false;
      if (seen || !mounted) return;
      // Pequeño delay para que las keys ya estén montadas
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _showTutorial();
    } catch (e) {
      debugPrint('Tutorial init error: $e');
    }
  }

  Future<void> _markTutorialSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tutorialPrefsKey, true);
    } catch (_) {}
  }

  void _showTutorial() {
    _tutorial = TutorialCoachMark(
      targets: _buildTutorialTargets(),
      opacityShadow: 0.85,
      paddingFocus: 8,
      textSkip: 'SALTAR',
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      onClickTarget: (_) {},
      onSkip: () {
        _markTutorialSeen();
        return true;
      },
      onFinish: _markTutorialSeen,
    );
    _tutorial!.show(context: context);
  }

  List<TargetFocus> _buildTutorialTargets() {
    return [
      TargetFocus(
        identify: 'tutorial_likes',
        keyTarget: _likeKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 18,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _tutorialContent(
              title: '¿Te gustó el ejercicio?',
              body:
                  'Pulsa el pulgar arriba si te ha gustado, o el de abajo si no. '
                  'Así sabremos qué ejercicios te resultan más motivadores.',
              step: 1,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'tutorial_semaforo',
        keyTarget: _semaforoKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 18,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _tutorialContent(
              title: 'Marca la dificultad',
              body:
                  'Verde = fácil, naranja = regular, rojo = MUY DIFÍCIL.\n\n'
                  'Es importante que marques rojo si no has podido hacerlo. '
                  'Tu profesional recibirá un aviso para cambiar el ejercicio.',
              step: 2,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'tutorial_timer',
        keyTarget: _timerKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 22,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _tutorialContent(
              title: 'Empieza tu rutina',
              body:
                  'Pulsa "COMENZAR RUTINA" para activar el temporizador y '
                  'hacer los ejercicios al ritmo que tu profesional te '
                  'recomendó. Puedes pausar y reanudar cuando quieras.',
              step: 3,
              isLast: true,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _tutorialContent({
    required String title,
    required String body,
    required int step,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'PASO $step / 3',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isLast ? 'Pulsa fuera para terminar' : 'Pulsa fuera para continuar →',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // 3. LÓGICA DEL TEMPORIZADOR
  // =========================================================
  void _startTimer() {
    if (_workoutTimer != null) _workoutTimer!.cancel();

    setState(() {
      _isTimerRunning = true;
      _isPaused = false;
      _currentSeconds = _cfgWork;
      _isWorking = true;
      _currentSet = 1;
    });

    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isPaused) return;

      setState(() {
        if (_currentSeconds > 0) {
          _currentSeconds--;
        } else {
          // Cambio de fase (Trabajo <-> Descanso)
          if (_isWorking) {
            if (_currentSet < _cfgSets) {
              _isWorking = false; // Toca descansar
              _currentSeconds = _cfgRest;
              HapticFeedback.heavyImpact(); // Vibración al cambiar
            } else {
              _stopTimer(); // Fin del ejercicio
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Entrenamiento completado! 🎉'),
                    backgroundColor: Colors.green,
                  ),
                );
                HapticFeedback.mediumImpact();
              }
            }
          } else {
            _isWorking = true; // Toca trabajar
            _currentSet++;
            _currentSeconds = _cfgWork;
            HapticFeedback.heavyImpact();
          }
        }
      });
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _stopTimer() {
    _workoutTimer?.cancel();
    if (mounted) {
      setState(() {
        _isTimerRunning = false;
        _isPaused = false;
        _currentSeconds = 0;
      });
    }
  }

  // Modal para configurar tiempos
  void _mostrarConfiguradorTimer() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        var tempSets = _cfgSets;
        var tempWork = _cfgWork;
        var tempRest = _cfgRest;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Center(
                    child: Text(
                      'Configurar Intervalos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStepper(
                    setModalState,
                    'Series',
                    tempSets,
                    (v) => tempSets = v,
                  ),
                  const Divider(),
                  _buildStepper(
                    setModalState,
                    'Trabajo (seg)',
                    tempWork,
                    (v) => tempWork = v,
                    step: 5,
                  ),
                  const Divider(),
                  _buildStepper(
                    setModalState,
                    'Descanso (seg)',
                    tempRest,
                    (v) => tempRest = v,
                    step: 5,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _cfgSets = tempSets;
                          _cfgWork = tempWork;
                          _cfgRest = tempRest;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'GUARDAR CONFIGURACIÓN',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Widget auxiliar para los contadores (+ / -)
  Widget _buildStepper(
    StateSetter setModalState,
    String label,
    int value,
    ValueChanged<int> onChange, {
    int step = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.teal,
                  size: 30,
                ),
                onPressed: () => setModalState(() {
                  var newValue = value;
                  if (newValue > step) newValue -= step;
                  onChange(newValue);
                }),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.teal,
                  size: 30,
                ),
                onPressed: () => setModalState(() {
                  var newValue = value;
                  newValue += step;
                  onChange(newValue);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // 4. INTERFAZ DE USUARIO (BUILD)
  // =========================================================
  @override
  Widget build(BuildContext context) {
    // viewPadding mantiene el inset de la barra de gestos / nav bar de
    // Android + safe area inferior de iPhone para que los botones del
    // temporizador no queden tapados por el sistema.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(
        0xFF1A1A1A,
      ), // Fondo oscuro para resaltar el video

      // AppBar Transparente sobre el fondo oscuro
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            // --- ZONA 1: REPRODUCTOR DE VIDEO (Flex 3) ---
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildVideoContent(),
                ),
              ),
            ),

            // --- ZONA 2: CONTROLES Y FEEDBACK (Flex 5) ---
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA), // Fondo claro para los controles
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 30, 20, 24 + bottomInset),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: <Widget>[
                      // Panel de Feedback
                      _buildFeedbackPanel(),

                      const SizedBox(height: 30),

                      // Panel de Temporizador (Activo o Inactivo)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isTimerRunning
                            ? _buildActiveTimer()
                            : _buildIdleTimer(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Sub-widgets de la UI ---

  Widget _buildVideoContent() {
    if (_isLoadingVideo) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }
    if (_isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Colors.white, size: 40),
              const SizedBox(height: 10),
              Text(
                'No se pudo cargar el video.\n$_errorMessage',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (_chewieController != null &&
        _videoPlayerController!.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    }
    return const SizedBox.shrink();
  }

  Widget _buildFeedbackPanel() {
    return SizedBox(
      height: 100,
      child: Row(
        children: <Widget>[
          // Caja izquierda: ¿Te gustó?
          Expanded(
            child: Container(
              key: _likeKey,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿Te gustó?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _feedbackIconBtn(
                        Icons.thumb_up,
                        true,
                        _leGusta ?? false,
                        Colors.green,
                      ),
                      _feedbackIconBtn(
                        Icons.thumb_down,
                        false,
                        _leGusta == false,
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Caja derecha: Dificultad
          Expanded(
            child: Container(
              key: _semaforoKey,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Dificultad',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _semaforoDot(Colors.green, 'facil'),
                      _semaforoDot(Colors.orange, 'medio'),
                      _semaforoDot(Colors.red, 'dificil'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedbackIconBtn(
    IconData icon,
    bool value,
    bool isActive,
    Color activeColor,
  ) {
    return InkWell(
      onTap: () => _enviarFeedback('gustado', value),
      child: Icon(
        icon,
        color: isActive ? activeColor : activeColor.withValues(alpha: 0.3),
        size: 30,
      ),
    );
  }

  Widget _semaforoDot(Color color, String valor) {
    final selected = _dificultad == valor;
    return InkWell(
      onTap: () => _enviarFeedback('dificultad', valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: selected ? 28 : 24,
        height: selected ? 28 : 24,
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 1 : 0.3),
          shape: BoxShape.circle,
          boxShadow: [
            if (selected)
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: selected
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildIdleTimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer_outlined, color: Colors.teal, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Temporizador',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _mostrarConfiguradorTimer,
                icon: const Icon(Icons.settings, color: Colors.teal),
                tooltip: 'Configurar',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _timerInfoBox('Series', '$_cfgSets'),
              _timerInfoBox('Trabajo', '${_cfgWork}s'),
              _timerInfoBox('Descanso', '${_cfgRest}s'),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            key: _timerKey,
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _startTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.teal.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 32),
              label: const Text(
                'COMENZAR RUTINA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timerInfoBox(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTimer() {
    final bg1 = _isWorking
        ? const Color(0xFF43A047)
        : const Color(
            0xFFFB8C00,
          ); // Verde trabajo, Naranja descanso
    final bg2 = _isWorking ? const Color(0xFF66BB6A) : const Color(0xFFFFA726);
    final phaseText = _isWorking ? '🔥 TRABAJO' : '💤 DESCANSO';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg1, bg2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: bg1.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SERIE $_currentSet / $_cfgSets',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  phaseText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '$_currentSeconds',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 90,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const Text(
            'segundos restantes',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _togglePause,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  label: Text(_isPaused ? 'REANUDAR' : 'PAUSAR'),
                ),
              ),
              const SizedBox(width: 15),
              IconButton.filled(
                onPressed: _stopTimer,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: bg1,
                  padding: const EdgeInsets.all(12),
                ),
                icon: const Icon(Icons.stop, size: 28),
                tooltip: 'Terminar',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
