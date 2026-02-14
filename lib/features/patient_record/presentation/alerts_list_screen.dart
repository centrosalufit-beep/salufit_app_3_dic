import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// RUTA RELATIVA CORREGIDA (misma carpeta)
import 'package:salufit_app/features/patient_record/presentation/admin_patient_detail_screen.dart';

class AlertsListScreen extends StatelessWidget {
  const AlertsListScreen({required this.viewerRole, super.key});
  final String viewerRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas de Feedback'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('exercise_assignments')
            .where('feedback.alerta', isEqualTo: true)
            .snapshots(),
        builder: (
          BuildContext context,
          AsyncSnapshot<QuerySnapshot<Object?>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.check_circle_outline,
                    size: 60,
                    color: Colors.green,
                  ),
                  SizedBox(height: 10),
                  Text('¡Todo limpio! No hay alertas pendientes.'),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (BuildContext c, int i) => const Divider(),
            itemBuilder: (BuildContext context, int index) {
              final data = docs[index].data()! as Map<String, dynamic>;

              final userId = data['userId'].toString();

              var feedback = <String, dynamic>{};
              if (data['feedback'] != null) {
                feedback = Map<String, dynamic>.from(data['feedback'] as Map);
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<DocumentSnapshot<Object?>> userSnap,
                ) {
                  var nombrePaciente = 'Usuario $userId';
                  if (userSnap.hasData && userSnap.data!.exists) {
                    final uData =
                        userSnap.data!.data()! as Map<String, dynamic>;
                    nombrePaciente =
                        uData['nombreCompleto']?.toString() ?? nombrePaciente;
                  }

                  return Card(
                    color: Colors.red.shade50,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 35,
                      ),
                      title: Text(
                        nombrePaciente,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('exercises')
                                .where(
                                  'codigoInterno',
                                  isEqualTo: int.tryParse(
                                        data['exerciseId'].toString(),
                                      ) ??
                                      -1,
                                )
                                .limit(1)
                                .get(),
                            builder: (
                              BuildContext context,
                              AsyncSnapshot<QuerySnapshot<Object?>>
                                  exerciseSnap,
                            ) {
                              var nombreEjercicio =
                                  "Ejercicio #${data['exerciseId']}";
                              if (exerciseSnap.hasData &&
                                  exerciseSnap.data!.docs.isNotEmpty) {
                                nombreEjercicio = exerciseSnap
                                    .data!.docs.first['nombre'] as String;
                              }
                              return Text('Ejercicio: $nombreEjercicio');
                            },
                          ),
                          Text(
                            "Queja: ${feedback['dificultad']?.toString().toUpperCase() ?? 'DESCONOCIDA'}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      // CORRECCIÓN: Agregado () antes de las llaves
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) =>
                                AdminPatientDetailScreen(
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
