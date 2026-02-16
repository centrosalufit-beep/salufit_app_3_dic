// lib/features/patient_record/presentation/video_player_screen.dart

import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback y orientación
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

  // --- URL HARDCODED (MODIFICACIÓN ARQUITECTO) ---
  final String _fixedVideoUrl =
      'https://firebasestorage.googleapis.com/v0/b/salufitnewapp.firebasestorage.app/o/1.mp4?alt=media&token=c4c35672-3da8-4ee4-9947-416b4a251e2d';

  @override
  void initState() {
    super.initState();
    debugPrint('🎬 Iniciando reproductor para: ${widget.title}');
    // Usamos la URL fija para asegurar que funcione el paso 3
    debugPrint('🔗 URL Fija aplicada: $_fixedVideoUrl');
    _initializePlayer();
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    // Restaurar orientación vertical al salir por si acaso
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  // =========================================================
  // 1. INICIALIZACIÓN DEL VIDEO (MODIFICADO)
  // =========================================================
  Future<void> _initializePlayer() async {
    // Nota del Arquitecto: Aquí ignoramos widget.videoUrl temporalmente
    // para asegurar la carga del video de prueba solicitado.

    try {
      // Intentamos cargar el video con la URL fija
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(_fixedVideoUrl),
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
    } on Exception catch (e) {
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
  void _enviarFeedback(String campo, Object valor) {
    HapticFeedback.lightImpact(); // Feedback táctil

    final updates = <String, Object?>{
      'feedback.$campo': valor,
      'feedback.fecha': FieldValue.serverTimestamp(),
      'feedback.alerta': (campo == 'gustado' && valor == false) ||
          (campo == 'dificultad' && valor == 'dificil'),
    };

    FirebaseFirestore.instance
        .collection('exercise_assignments')
        .doc(widget.assignmentId)
        .update(updates);

    setState(() {
      if (campo == 'gustado' && valor is bool) {
        _leGusta = valor;
      }
      if (campo == 'dificultad' && valor is String) {
        _dificultad = valor;
      }
    });
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

      body: Column(
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
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
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

                    const SizedBox(height: 20), // Padding extra abajo
                  ],
                ),
              ),
            ),
          ),
        ],
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
