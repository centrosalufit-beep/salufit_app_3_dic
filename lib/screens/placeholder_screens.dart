import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 

class DashboardScreen extends StatelessWidget {
  final String userId;
  
  const DashboardScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // 1. IDs Híbridos
    String idConCeros = userId.padLeft(6, '0');
    String idSinCeros = userId.replaceFirst(RegExp(r'^0+'), '');
    List<dynamic> posiblesIds = [idConCeros, idSinCeros];
    if (int.tryParse(idSinCeros) != null) {
      posiblesIds.add(int.parse(idSinCeros));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Salufit Inicio", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SALUDO
            const Text("Hola de nuevo,", style: TextStyle(fontSize: 16, color: Colors.grey)),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(idConCeros).snapshots(),
              builder: (context, snapshot) {
                String nombreMostrar = "Usuario $userId"; 
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  String nombreCompleto = data['nombreCompleto'] ?? data['nombre'] ?? "";
                  if (nombreCompleto.isNotEmpty) nombreMostrar = nombreCompleto.split(' ')[0]; 
                }
                return Text(nombreMostrar, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black));
              },
            ),
            
            const SizedBox(height: 30),

            // --- TARJETA: PRÓXIMA CLASE (Lógica Corregida) ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings')
                  .where('userId', whereIn: posiblesIds)
                  .orderBy('fechaReserva', descending: true) // Traemos las últimas creadas
                  .limit(20) // Miramos las últimas 20 para encontrar la próxima
                  .snapshots(),
              builder: (context, snapshot) {
                // SI FALTA ÍNDICE, MOSTRAMOS ERROR VISUAL
                if (snapshot.hasError) {
                   return Container(
                     padding: const EdgeInsets.all(10),
                     color: Colors.red.shade100,
                     child: Text("Error (Falta Índice): ${snapshot.error}", style: const TextStyle(color: Colors.red, fontSize: 10)),
                   );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyClassCard();

                // Buscamos la clase futura más cercana
                return FutureBuilder<DocumentSnapshot?>(
                  future: _findNextClass(snapshot.data!.docs),
                  builder: (context, classSnap) {
                    if (!classSnap.hasData || classSnap.data == null) return _buildEmptyClassCard();
                    
                    var classData = classSnap.data!.data() as Map<String, dynamic>;
                    String nombreClase = classData['nombre'] ?? "Clase";
                    Timestamp ts = classData['fechaHoraInicio'];
                    DateTime fecha = ts.toDate();
                    
                    String dia = DateFormat('EEEE d', 'es').format(fecha);
                    String hora = DateFormat('HH:mm').format(fecha);
                    dia = "${dia[0].toUpperCase()}${dia.substring(1)}";

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                        border: Border(left: BorderSide(color: Colors.blue.shade400, width: 5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("TU PRÓXIMA CLASE", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                              Icon(Icons.fitness_center, color: Colors.blue.shade200),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(nombreClase, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text("$dia a las $hora", style: TextStyle(color: Colors.grey.shade800)),
                        ],
                      ),
                    );
                  },
                );
              }
            ),

            const SizedBox(height: 20),

            // --- TARJETA: PRÓXIMA CITA ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('appointments')
                  .where('userId', whereIn: posiblesIds)
                  .where('fechaHoraInicio', isGreaterThan: Timestamp.now())
                  .orderBy('fechaHoraInicio')
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const SizedBox(); // Aquí ocultamos si falla para no ensuciar
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
                    child: const Text("No tienes citas médicas próximas", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  );
                }
                var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                DateTime fecha = (data['fechaHoraInicio'] as Timestamp).toDate();
                String dia = DateFormat('EEEE d MMMM', 'es').format(fecha);
                dia = "${dia[0].toUpperCase()}${dia.substring(1)}";
                String hora = DateFormat('H:mm').format(fecha);

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))], border: Border(left: BorderSide(color: Colors.orange.shade400, width: 5))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("PRÓXIMA CITA", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)), Icon(Icons.calendar_month, color: Colors.orange.shade200)]),
                      const SizedBox(height: 10),
                      Text(data['especialidad'] ?? 'Cita', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Row(children: [Icon(Icons.access_time, size: 18, color: Colors.grey.shade600), const SizedBox(width: 5), Text("$dia a las $hora", style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold))])
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 50), 
          ],
        ),
      ),
    );
  }

  // Buscamos la clase futura más cercana
  Future<DocumentSnapshot?> _findNextClass(List<QueryDocumentSnapshot> bookings) async {
    DateTime now = DateTime.now();
    DateTime? closestDate;
    DocumentSnapshot? closestClass;

    for (var doc in bookings) {
      var data = doc.data() as Map<String, dynamic>;
      if (data['groupClassId'] == null) continue;

      var classDoc = await FirebaseFirestore.instance.collection('groupClasses').doc(data['groupClassId']).get();
      
      if (classDoc.exists) {
        Timestamp? ts = classDoc.data()!['fechaHoraInicio'];
        if (ts != null) {
          DateTime date = ts.toDate();
          // Solo si es futura
          if (date.isAfter(now)) {
            if (closestDate == null || date.isBefore(closestDate)) {
              closestDate = date;
              closestClass = classDoc;
            }
          }
        }
      }
    }
    return closestClass;
  }

  Widget _buildEmptyClassCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border(left: BorderSide(color: Colors.grey.shade300, width: 5))),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("TU PRÓXIMA CLASE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
        SizedBox(height: 10),
        Text("Sin reservas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
        SizedBox(height: 5),
        Text("Consulta la pestaña Clases", style: TextStyle(color: Colors.grey)),
      ]),
    );
  }
}