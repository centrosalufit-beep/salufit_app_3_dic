import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String assignmentId; // ID de la asignación para guardar el feedback

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
  
  // Estado del Feedback
  bool? _leGusta; // null, true, false
  String? _dificultad; // 'facil', 'medio', 'dificil'

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoPlayerController.initialize();
      
      // --- CORRECCIÓN DE SEGURIDAD APLICADA ---
      // Si el usuario sale de la pantalla antes de que el vídeo cargue, 
      // paramos aquí para evitar llamar a setState() en un widget destruido.
      if (!mounted) return; 
      // ----------------------------------------
      
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: true,
          looping: true,
          aspectRatio: _videoPlayerController.value.aspectRatio,
          errorBuilder: (context, errorMessage) {
            return Center(child: Text("Error: $errorMessage", style: const TextStyle(color: Colors.white)));
          },
        );
      });
    } catch (e) {
      print("Error video: $e");
      // También comprobamos mounted aquí por seguridad
      if (mounted) setState(() { _isError = true; });
    }
  }

  // Función para guardar Feedback en Firebase
  void _enviarFeedback(String campo, dynamic valor) {
    FirebaseFirestore.instance
        .collection('exercise_assignments')
        .doc(widget.assignmentId)
        .update({
          'feedback.$campo': valor,
          'feedback.fecha': FieldValue.serverTimestamp(),
          // Si es negativo, marcamos para alerta (opcional)
          'feedback.alerta': (campo == 'gustado' && valor == false) || (campo == 'dificultad' && valor == 'dificil')
        });
    
    setState(() {
      if (campo == 'gustado') _leGusta = valor;
      if (campo == 'dificultad') _dificultad = valor;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gracias por tu opinión"), duration: Duration(seconds: 1)));
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ZONA VIDEO
          Expanded(
            flex: 2,
            child: Center(
              child: _isError
                  ? const Text("Error al cargar video", style: TextStyle(color: Colors.white))
                  : _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                      ? Chewie(controller: _chewieController!)
                      : const CircularProgressIndicator(color: Colors.white),
            ),
          ),

          // ZONA FEEDBACK
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text("¿Qué te ha parecido?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                // 1. PULGARES
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.thumb_up, color: _leGusta == true ? Colors.green : Colors.grey, size: 40),
                      onPressed: () => _enviarFeedback('gustado', true),
                    ),
                    const SizedBox(width: 40),
                    IconButton(
                      icon: Icon(Icons.thumb_down, color: _leGusta == false ? Colors.red : Colors.grey, size: 40),
                      onPressed: () => _enviarFeedback('gustado', false),
                    ),
                  ],
                ),
                
                const Divider(height: 30),
                const Text("Dificultad", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                // 2. SEMÁFORO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _botonSemaforo("Fácil", Colors.green, 'facil'),
                    _botonSemaforo("Me costó", Colors.orange, 'medio'),
                    _botonSemaforo("Imposible", Colors.red, 'dificil'),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _botonSemaforo(String texto, Color color, String valor) {
    bool seleccionado = _dificultad == valor;
    return InkWell(
      onTap: () => _enviarFeedback('dificultad', valor),
      child: Column(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(seleccionado ? 1 : 0.3),
              shape: BoxShape.circle,
              border: seleccionado ? Border.all(color: Colors.black, width: 2) : null
            ),
            child: seleccionado ? const Icon(Icons.check, color: Colors.white) : null,
          ),
          const SizedBox(height: 5),
          Text(texto, style: TextStyle(fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}