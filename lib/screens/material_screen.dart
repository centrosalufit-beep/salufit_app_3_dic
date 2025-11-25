import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'video_player_screen.dart';

class MaterialScreen extends StatelessWidget {
  final String userId;

  const MaterialScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Mis Ejercicios Pautados", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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

  // --- NUEVA LÓGICA: BUSCAR POR CAMPO 'ORDEN' ---
  Future<QuerySnapshot> _fetchExerciseByOrder(String exerciseIdFromAssignment) {
    // Intentamos convertir lo que viene del Excel (ej: "25") a número
    int ordenBuscado = int.tryParse(exerciseIdFromAssignment) ?? -1;
    
    // Buscamos en el catálogo el documento que tenga ese orden
    return FirebaseFirestore.instance
        .collection('exercises')
        .where('orden', isEqualTo: ordenBuscado) // <--- AQUÍ ESTÁ LA CLAVE
        .limit(1)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    // Preparamos IDs híbridos
    String idConCeros = widget.currentUserId;
    String idSinCeros = widget.currentUserId.replaceFirst(RegExp(r'^0+'), '');
    List<dynamic> posiblesIds = [idConCeros, idSinCeros];
    if (int.tryParse(idSinCeros) != null) posiblesIds.add(int.parse(idSinCeros));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exercise_assignments')
          .where('userId', whereIn: posiblesIds)
          .orderBy('fechaAsignacion', descending: true) 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
           // Si falta un índice compuesto, aquí saldrá el link
           // print("Error Material: ${snapshot.error}");
           return const Center(child: Text("Cargando ejercicios...")); 
        }
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library_outlined, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                const Text("No tienes ejercicios asignados", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 15),
          itemBuilder: (context, index) {
            var assignmentDoc = snapshot.data!.docs[index];
            var assignmentData = assignmentDoc.data() as Map<String, dynamic>;
            
            // Este es el número "25" o "15" que viene del Excel
            String exerciseIdFromExcel = assignmentData['exerciseId'].toString();
            String instrucciones = assignmentData['instrucciones'] ?? "Sin instrucciones específicas.";
            String assignmentId = assignmentDoc.id; 

            // BÚSQUEDA INTELIGENTE: Buscamos el vídeo que tenga orden: 25
            return FutureBuilder<QuerySnapshot>(
              future: _fetchExerciseByOrder(exerciseIdFromExcel),
              builder: (context, videoSnapshot) {
                
                if (!videoSnapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                
                // Si no encontramos ningún vídeo con orden 25:
                if (videoSnapshot.data!.docs.isEmpty) {
                   return Card(
                     color: Colors.red.shade50,
                     child: Padding(
                       padding: const EdgeInsets.all(15), 
                       child: Row(
                         children: [
                           const Icon(Icons.error_outline, color: Colors.red),
                           const SizedBox(width: 10),
                           Expanded(child: Text("Ejercicio #$exerciseIdFromExcel no encontrado en catálogo", style: const TextStyle(color: Colors.red))),
                         ],
                       )
                     )
                   );
                }

                // ¡Encontrado!
                var videoDoc = videoSnapshot.data!.docs.first;
                var videoData = videoDoc.data() as Map<String, dynamic>;
                
                String titulo = videoData['nombre'] ?? "Ejercicio";
                String urlVideo = videoData['urlVideo'] ?? "";
                String area = videoData['area'] ?? "";

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: InkWell(
                    onTap: () {
                      if (urlVideo.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(
                              videoUrl: urlVideo,
                              title: titulo,
                              assignmentId: assignmentId,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Este ejercicio no tiene video enlazado")));
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.blue, size: 40),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(area.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.yellow.shade200)
                            ),
                            child: Text("📝 $instrucciones", style: TextStyle(fontSize: 13, color: Colors.brown.shade800)),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}