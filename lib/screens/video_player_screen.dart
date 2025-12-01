import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String assignmentId;

  const VideoPlayerScreen({
    super.key, 
    required this.videoUrl, 
    required this.title,
    required this.assignmentId
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isError = false;
  
  // Feedback
  bool? _leGusta;
  String? _dificultad;

  // Timer Logic
  Timer? _workoutTimer;
  int _currentSeconds = 0;
  bool _isTimerRunning = false;
  bool _isPaused = false;
  bool _isWorking = true; 
  int _currentSet = 1;
  
  // --- CONFIGURACIÓN TIMER ---
  int _cfgSets = 2;
  int _cfgWork = 60;
  int _cfgRest = 40;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
      
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: token != null ? {
          'Authorization': 'Bearer $token' 
        } : {},
      );

      await _videoPlayerController.initialize();
      
      if (!mounted) return; 
      
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: true,
          looping: true,
          aspectRatio: _videoPlayerController.value.aspectRatio,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.teal,
            handleColor: Colors.tealAccent,
            backgroundColor: Colors.grey,
            bufferedColor: Colors.white30,
          ),
          errorBuilder: (context, errorMessage) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error reproduciendo: $errorMessage\n\nSi persiste, verifica tu conexión.',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            )
          ),
        );
      });
    } catch (e) {
      debugPrint('🔴 Error vídeo: $e');
      if (mounted) setState(() { _isError = true; });
    }
  }

  void _enviarFeedback(String campo, dynamic valor) {
    FirebaseFirestore.instance.collection('exercise_assignments').doc(widget.assignmentId).update({
      'feedback.$campo': valor,
      'feedback.fecha': FieldValue.serverTimestamp(),
      'feedback.alerta': (campo == 'gustado' && valor == false) || (campo == 'dificultad' && valor == 'dificil')
    });
    setState(() {
      if (campo == 'gustado') _leGusta = valor;
      if (campo == 'dificultad') _dificultad = valor;
    });
  }

  // --- LÓGICA DEL TIMER ---
  void _startTimer() {
    if (_workoutTimer != null) _workoutTimer!.cancel();
    setState(() {
      _isTimerRunning = true;
      _isPaused = false;
      _currentSeconds = _cfgWork;
      _isWorking = true;
      _currentSet = 1;
    });

    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_isPaused) return; 

      setState(() {
        if (_currentSeconds > 0) {
          _currentSeconds--;
        } else {
          if (_isWorking) {
            if (_currentSet < _cfgSets) {
              _isWorking = false; 
              _currentSeconds = _cfgRest;
            } else {
              _stopTimer(); 
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Entrenamiento completado! 🎉'), backgroundColor: Colors.green));
              }
            }
          } else {
            _isWorking = true; 
            _currentSet++;
            _currentSeconds = _cfgWork;
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
    if (_workoutTimer != null) _workoutTimer!.cancel();
    if (mounted) {
      setState(() { 
        _isTimerRunning = false; 
        _isPaused = false;
        _currentSeconds = 0; 
      });
    }
  }

  void _mostrarConfiguradorTimer() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        int tempSets = _cfgSets;
        int tempWork = _cfgWork;
        int tempRest = _cfgRest;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 350,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Configurar Intervalos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildStepper(setModalState, 'Series', tempSets, (v) => tempSets = v),
                  _buildStepper(setModalState, 'Trabajo (seg)', tempWork, (v) => tempWork = v, step: 5),
                  _buildStepper(setModalState, 'Descanso (seg)', tempRest, (v) => tempRest = v, step: 5),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      onPressed: () {
                        setState(() {
                          _cfgSets = tempSets;
                          _cfgWork = tempWork;
                          _cfgRest = tempRest;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('GUARDAR CONFIGURACIÓN'),
                    ),
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildStepper(Function setStateFunc, String label, int value, Function(int) onChange, {int step = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.teal), onPressed: () => setStateFunc(() { if (value > step) value -= step; onChange(value); })),
              SizedBox(
                width: 40,
                child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.teal), onPressed: () => setStateFunc(() { value += step; onChange(value); })),
            ],
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // 1. ZONA VIDEO (FLEX 3)
          Expanded(
            flex: 3, 
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Center(
                  child: _isError
                      ? const Text('Error al cargar video (403)', style: TextStyle(color: Colors.white))
                      : _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                          ? Chewie(controller: _chewieController!)
                          : const CircularProgressIndicator(color: Colors.teal),
                ),
              ),
            ),
          ),

          // 2. PANEL CONTROL CON FONDO ACUARELA (FLEX 5)
          Expanded(
            flex: 5, 
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA), // Color base blanco suave
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                
                // ---> CORRECCIÓN AQUÍ <---
                image: DecorationImage(
                  // Antes decía 'assets/images/login_bg.jpg', ahora coincide con pubspec:
                  image: AssetImage('assets/login_bg.jpg'), 
                  fit: BoxFit.cover, 
                  opacity: 0.3,
                )
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20, 
                    right: 20, 
                    top: 25, 
                    bottom: MediaQuery.of(context).padding.bottom + 20
                  ),
                  child: Column(
                    children: [
                      // SECCIÓN FEEDBACK (Transparente con toque Teal)
                      SizedBox(
                        height: 90,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.1), // Cristal teal
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('¿Te gustó?', style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        InkWell(onTap: () => _enviarFeedback('gustado', true), child: Icon(Icons.thumb_up, color: _leGusta == true ? Colors.green : Colors.green.withValues(alpha: 0.4), size: 32)),
                                        InkWell(onTap: () => _enviarFeedback('gustado', false), child: Icon(Icons.thumb_down, color: _leGusta == false ? Colors.red : Colors.red.withValues(alpha: 0.4), size: 32)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.1), // Cristal teal
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Dificultad', style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _semaforoDot(Colors.green, 'facil'),
                                        _semaforoDot(Colors.orange, 'medio'),
                                        _semaforoDot(Colors.red, 'dificil'),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25), 

                      // SECCIÓN TIMER
                      _isTimerRunning ? _buildActiveTimer() : _buildIdleTimer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _semaforoDot(Color color, String valor) {
    final bool selected = _dificultad == valor;
    return InkWell(
      onTap: () => _enviarFeedback('dificultad', valor),
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 1.0 : 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black12, width: 1.5)
        ),
        child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
      ),
    );
  }

  Widget _buildIdleTimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.1), // Cristal teal
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer, color: Colors.teal),
                  SizedBox(width: 10),
                  Text('Temporizador', style: TextStyle(color: Colors.teal, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                onPressed: _mostrarConfiguradorTimer,
                icon: const Icon(Icons.edit, color: Colors.teal),
                tooltip: 'Editar Tiempos',
              )
            ],
          ),
          
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _timerStat('$_cfgSets', 'Series', Colors.black87),
              Container(width: 1, height: 30, color: Colors.teal.withValues(alpha: 0.3)), 
              _timerStat('${_cfgWork}s', 'Trabajo', Colors.black87),
              Container(width: 1, height: 30, color: Colors.teal.withValues(alpha: 0.3)), 
              _timerStat('${_cfgRest}s', 'Descanso', Colors.black87),
            ],
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _startTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 2,
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 30),
              label: const Text('COMENZAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _timerStat(String val, String label, [Color color = Colors.white]) {
    return Column(
      children: [
        Text(val, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10)),
      ],
    );
  }

  Widget _buildActiveTimer() {
    final Color bg1 = _isWorking ? const Color(0xFF43A047) : const Color(0xFFFB8C00); 
    final Color bg2 = _isWorking ? const Color(0xFF66BB6A) : const Color(0xFFFFA726);
    final String phaseText = _isWorking ? '🔥 TRABAJO' : '💤 DESCANSO';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [bg1, bg2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: bg1.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SERIE $_currentSet / $_cfgSets', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                child: Text(phaseText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
          
          const SizedBox(height: 30),
          
          Text(
            '$_currentSeconds', 
            style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold, height: 1)
          ),
          const Text('segundos', style: TextStyle(color: Colors.white70)),
          
          const SizedBox(height: 30),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _togglePause,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white, elevation: 0),
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  label: Text(_isPaused ? 'REANUDAR' : 'PAUSAR'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _stopTimer,
                style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: bg1),
                icon: const Icon(Icons.stop),
                tooltip: 'Detener',
              )
            ],
          )
        ],
      ),
    );
  }
}