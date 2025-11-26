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
            // --- SALUDO ---
            const Text("Hola de nuevo,", style: TextStyle(fontSize: 16, color: Colors.grey)),
            FutureBuilder<DocumentSnapshot>(
              future: _fetchUserProfile(idConCeros, idSinCeros),
              builder: (context, snapshot) {
                String nombreMostrar = "Usuario"; 
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  String nombreCompleto = data['nombreCompleto'] ?? data['nombre'] ?? "";
                  if (nombreCompleto.isNotEmpty) {
                    nombreMostrar = nombreCompleto.split(' ')[0]; 
                    if (nombreMostrar.isNotEmpty) {
                      nombreMostrar = "${nombreMostrar[0].toUpperCase()}${nombreMostrar.substring(1).toLowerCase()}";
                    }
                  }
                }
                return Text(nombreMostrar, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black));
              },
            ),
            
            const SizedBox(height: 30),

            // --- SECCIÓN 1: PRÓXIMA CLASE (Lógica Original) ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings')
                  .where('userId', whereIn: posiblesIds)
                  .orderBy('fechaReserva', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return _buildEmptyClassCard();
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyClassCard();

                return FutureBuilder<DocumentSnapshot?>(
                  future: _findNextClass(snapshot.data!.docs),
                  builder: (context, classSnap) {
                    if (!classSnap.hasData || classSnap.data == null) return _buildEmptyClassCard();
                    
                    var classData = classSnap.data!.data() as Map<String, dynamic>;
                    String nombreClase = classData['nombre'] ?? "Clase";
                    Timestamp? ts = classData['fechaHoraInicio'];
                    
                    if (ts == null) return _buildEmptyClassCard();

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

            const SizedBox(height: 25),

            // --- SECCIÓN 2: CITAS MÉDICAS (Lógica Nueva: Lista Completa) ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('appointments')
                  .where('userId', whereIn: posiblesIds)
                  .where('fechaHoraInicio', isGreaterThan: Timestamp.now())
                  .orderBy('fechaHoraInicio') // Ordenamos de más próxima a más lejana
                  .limit(10) // Traemos hasta 10 futuras
                  .snapshots(),
              builder: (context, snapshot) {
                // 1. Estado de Carga o Vacío
                if (snapshot.hasError) return const SizedBox();
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
                    child: const Text("No tienes citas médicas próximas", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  );
                }
                
                // 2. Separamos la primera cita del resto
                var todasLasCitas = snapshot.data!.docs;
                var proximaCita = todasLasCitas.first; // La más urgente
                var restoDeCitas = todasLasCitas.skip(1).toList(); // El resto

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TARJETA DESTACADA (La primera) ---
                    _buildMainAppointmentCard(proximaCita),

                    // --- LISTA DEL RESTO (Si hay más) ---
                    if (restoDeCitas.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text("Próximamente", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 10),
                      
                      // Mapeamos el resto de citas como tarjetas pequeñas
                      ...restoDeCitas.map((doc) => _buildSecondaryAppointmentCard(doc)),
                    ]
                  ],
                );
              },
            ),
            const SizedBox(height: 50), 
          ],
        ),
      ),
    );
  }

  // --- WIDGET: Tarjeta Destacada (Naranja Grande) ---
  Widget _buildMainAppointmentCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    DateTime fecha = (data['fechaHoraInicio'] as Timestamp).toDate();
    String dia = DateFormat('EEEE d MMMM', 'es').format(fecha);
    dia = "${dia[0].toUpperCase()}${dia.substring(1)}";
    String hora = DateFormat('H:mm').format(fecha);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))], 
        border: Border(left: BorderSide(color: Colors.orange.shade400, width: 5))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              const Text("PRÓXIMA CITA", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)), 
              Icon(Icons.calendar_month, color: Colors.orange.shade200)
            ]
          ),
          const SizedBox(height: 10),
          Text(data['especialidad'] ?? 'Cita Médica', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: Colors.grey.shade600), 
              const SizedBox(width: 5), 
              Text("$dia a las $hora", style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold))
            ]
          )
        ],
      ),
    );
  }

  // --- WIDGET: Tarjeta Secundaria (Blanca Compacta) ---
  Widget _buildSecondaryAppointmentCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    DateTime fecha = (data['fechaHoraInicio'] as Timestamp).toDate();
    String diaCorto = DateFormat('dd/MM/yyyy').format(fecha);
    String hora = DateFormat('H:mm').format(fecha);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['especialidad'] ?? 'Cita', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("$diaCorto - $hora", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FUNCIONES AUXILIARES (Iguales que antes) ---
  Future<DocumentSnapshot> _fetchUserProfile(String idConCeros, String idSinCeros) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(idConCeros).get();
    if (doc.exists) return doc;
    QuerySnapshot query = await FirebaseFirestore.instance.collection('users')
        .where('id', whereIn: [idConCeros, idSinCeros, int.tryParse(idSinCeros)])
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) return query.docs.first;
    return doc;
  }

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