import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:intl/intl.dart'; 
import '../widgets/salufit_scaffold.dart'; // <--- IMPORT NUEVO

class DashboardScreen extends StatelessWidget {
  final String userId;
  
  const DashboardScreen({super.key, required this.userId});

  Map<String, dynamic> _getClassVisuals(String nombreClase) {
    String nombre = nombreClase.toLowerCase();
    if (nombre.contains('entrenamiento')) return {'colors': [const Color(0xFFD32F2F), const Color(0xFFE57373)], 'icon': Icons.fitness_center, 'label': 'ENTRENAMIENTO'};
    if (nombre.contains('meditación') || nombre.contains('meditacion')) return {'colors': [const Color(0xFF7B1FA2), const Color(0xFFBA68C8)], 'icon': Icons.self_improvement, 'label': 'MEDITACIÓN'};
    if (nombre.contains('tribu')) return {'colors': [const Color(0xFFF57C00), const Color(0xFFFFB74D)], 'icon': Icons.directions_walk, 'label': 'TRIBU ACTIVA'};
    return {'colors': [const Color(0xFF1976D2), const Color(0xFF64B5F6)], 'icon': Icons.sports_gymnastics, 'label': 'EJERCICIO TERAPÉUTICO'};
  }

  Map<String, dynamic> _getMedicalVisuals() {
    return {'colors': [const Color(0xFF009688), const Color(0xFF4DB6AC)], 'icon': Icons.medical_services_outlined, 'label': 'CITA MÉDICA'};
  }

  @override
  Widget build(BuildContext context) {
    // OBTENEMOS EMAIL PARA LA CONSULTA SEGURA
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail == null) return const Center(child: Text("Error de sesión"));

    return SalufitScaffold( // <--- CAMBIO A WIDGET CON FONDO
      // backgroundColor: const Color(0xFFF5F7FA), // Ya viene por defecto
      appBar: AppBar(
        title: const Text("Salufit Inicio", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)), 
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        automaticallyImplyLeading: false
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hola de nuevo,", style: TextStyle(fontSize: 16, color: Colors.grey)),
            
            // PERFIL: Buscamos por email para obtener el nombre
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userEmail).limit(1).get(),
              builder: (context, snapshot) {
                String nombreMostrar = "Usuario"; 
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  String nombreCompleto = data['nombreCompleto'] ?? data['nombre'] ?? "";
                  if (nombreCompleto.isNotEmpty) {
                    nombreMostrar = nombreCompleto.split(' ')[0]; 
                    if (nombreMostrar.isNotEmpty) nombreMostrar = "${nombreMostrar[0].toUpperCase()}${nombreMostrar.substring(1).toLowerCase()}";
                  }
                }
                return Text(nombreMostrar, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black));
              },
            ),
            const SizedBox(height: 30),

            // SECCIÓN 1: PRÓXIMA CLASE
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings')
                  .where('userEmail', isEqualTo: userEmail) 
                  .orderBy('fechaReserva', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return _buildEmptyCard("TU PRÓXIMA CLASE", "Error: ${snapshot.error}", Icons.error);
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyCard("TU PRÓXIMA CLASE", "Sin reservas activas", Icons.fitness_center);

                return FutureBuilder<DocumentSnapshot?>(
                  future: _findNextClass(snapshot.data!.docs),
                  builder: (context, classSnap) {
                    if (!classSnap.hasData || classSnap.data == null) return _buildEmptyCard("TU PRÓXIMA CLASE", "Sin clases próximas", Icons.fitness_center);
                    
                    var classData = classSnap.data!.data() as Map<String, dynamic>;
                    String nombreClase = classData['nombre'] ?? "Clase";
                    Timestamp? ts = classData['fechaHoraInicio'];
                    if (ts == null) return _buildEmptyCard("TU PRÓXIMA CLASE", "Error en datos", Icons.error);

                    DateTime fecha = ts.toDate();
                    String dia = DateFormat('EEEE d', 'es').format(fecha);
                    String hora = DateFormat('HH:mm').format(fecha);
                    dia = "${dia[0].toUpperCase()}${dia.substring(1)}";
                    var visual = _getClassVisuals(nombreClase);

                    return _buildDiscoverCard(title: "TU PRÓXIMA CLASE", mainText: nombreClase, subText: "$dia a las $hora", colors: visual['colors'], icon: visual['icon']);
                  },
                );
              }
            ),
            const SizedBox(height: 25),

            // SECCIÓN 2: PRÓXIMA CITA
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('appointments')
                  .where('userEmail', isEqualTo: userEmail) 
                  .where('fechaHoraInicio', isGreaterThan: Timestamp.now())
                  .orderBy('fechaHoraInicio') 
                  .limit(10) 
                  .snapshots(),
              builder: (context, snapshot) {
                
                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.red.shade50, border: Border.all(color: Colors.red), borderRadius: BorderRadius.circular(10)),
                    child: SelectableText("⚠️ Copia Link Índice:\n${snapshot.error}", style: const TextStyle(color: Colors.red)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                   return Container(
                     padding: const EdgeInsets.all(20), 
                     width: double.infinity, 
                     decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)), 
                     child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.calendar_today, color: Colors.grey), SizedBox(width: 10), Text("No tienes citas médicas próximas", style: TextStyle(color: Colors.grey))])
                   );
                }
                
                var proximaCita = snapshot.data!.docs.first;
                var restoDeCitas = snapshot.data!.docs.skip(1).toList();
                var data = proximaCita.data() as Map<String, dynamic>;
                DateTime fecha = (data['fechaHoraInicio'] as Timestamp).toDate();
                String dia = DateFormat('EEEE d MMMM', 'es').format(fecha);
                dia = "${dia[0].toUpperCase()}${dia.substring(1)}";
                String hora = DateFormat('H:mm').format(fecha);
                var visualMed = _getMedicalVisuals();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDiscoverCard(title: "PRÓXIMA CITA", mainText: data['especialidad'] ?? 'Cita Médica', subText: "$dia a las $hora", colors: visualMed['colors'], icon: visualMed['icon']),
                    if (restoDeCitas.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text("Próximamente", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 10),
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

  Widget _buildDiscoverCard({required String title, required String mainText, required String subText, required List<Color> colors, required IconData icon}) {
    return Container(height: 120, decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: colors[0].withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))]), child: Stack(children: [Positioned(right: -15, bottom: -15, child: Icon(icon, size: 130, color: Colors.white.withOpacity(0.15))), Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)), const SizedBox(height: 5), Text(mainText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 5), Row(children: [const Icon(Icons.access_time, color: Colors.white, size: 16), const SizedBox(width: 5), Text(subText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))])]))]));
  }

  Widget _buildSecondaryAppointmentCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    DateTime fecha = (data['fechaHoraInicio'] as Timestamp).toDate();
    String diaCorto = DateFormat('dd/MM/yyyy').format(fecha);
    String hora = DateFormat('H:mm').format(fecha);
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.calendar_today, size: 16, color: Colors.teal)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['especialidad'] ?? 'Cita', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text("$diaCorto - $hora", style: const TextStyle(color: Colors.grey, fontSize: 13))]))]));
  }

  Widget _buildEmptyCard(String title, String message, IconData icon) {
    return Container(padding: const EdgeInsets.all(20), width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 10), Row(children: [Icon(icon, color: Colors.grey.shade300, size: 30), const SizedBox(width: 10), Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey))])]));
  }

  Future<DocumentSnapshot> _fetchUserProfile(String userIdExacto) async {
    // Búsqueda directa por ID, mucho más eficiente
    return FirebaseFirestore.instance.collection('users').doc(userIdExacto).get();
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
}