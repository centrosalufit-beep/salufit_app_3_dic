import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_patient_detail_screen.dart'; 

class AlertsListScreen extends StatelessWidget {
  final String viewerRole;

  const AlertsListScreen({super.key, required this.viewerRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alertas de Feedback"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('exercise_assignments')
            .where('feedback.alerta', isEqualTo: true) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                  SizedBox(height: 10),
                  Text("¡Todo limpio! No hay alertas pendientes."),
                ],
              ),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              
              // --- CORRECCIÓN DEL ERROR 3502 ---
              // Usamos .toString() para que si viene un número (int), no falle.
              String userId = data['userId'].toString(); 
              
              // Protección extra para el feedback
              Map<String, dynamic> feedback = {};
              if (data['feedback'] != null) {
                 feedback = Map<String, dynamic>.from(data['feedback'] as Map);
              }

              // Buscamos el nombre del paciente
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnap) {
                  String nombrePaciente = "Usuario $userId";
                  if (userSnap.hasData && userSnap.data!.exists) {
                    var uData = userSnap.data!.data() as Map<String, dynamic>;
                    nombrePaciente = uData['nombreCompleto'] ?? nombrePaciente;
                  }

                  return Card(
                    color: Colors.red.shade50,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.red, width: 1),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 35),
                      title: Text(nombrePaciente, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          // --- BÚSQUEDA SEGURA DEL NOMBRE DEL EJERCICIO ---
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('exercises')
                                .where('codigoInterno', isEqualTo: int.tryParse(data['exerciseId'].toString()) ?? -1)
                                .limit(1)
                                .get(),
                            builder: (context, exerciseSnap) {
                              String nombreEjercicio = "Ejercicio #${data['exerciseId']}"; 
                              
                              if (exerciseSnap.hasData && exerciseSnap.data!.docs.isNotEmpty) {
                                nombreEjercicio = exerciseSnap.data!.docs.first['nombre'];
                              }
                              
                              return Text("Ejercicio: $nombreEjercicio");
                            },
                          ),
                          
                          Text(
                            "Queja: ${feedback['dificultad']?.toString().toUpperCase() ?? 'DESCONOCIDA'}",
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminPatientDetailScreen(
                              userId: userId,
                              userName: nombrePaciente,
                              viewerRole: viewerRole,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}