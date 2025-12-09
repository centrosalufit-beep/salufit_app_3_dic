import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Necesario para el fallback
import 'package:intl/intl.dart'; 
import '../widgets/salufit_scaffold.dart'; 

class DashboardScreen extends StatelessWidget {
  final String userId;
  
  final Color salufitGreen = const Color(0xFF009688); 

  const DashboardScreen({super.key, required this.userId});

  // --- LÓGICA VISUAL ---
  Map<String, dynamic> _getClassVisuals(String nombreClase) {
    final String nombre = nombreClase.toLowerCase();
    if (nombre.contains('entrenamiento')) {
      return {'colors': [const Color(0xFFD32F2F), const Color(0xFFE57373)], 'icon': Icons.fitness_center, 'label': 'ENTRENAMIENTO'};
    }
    if (nombre.contains('meditación') || nombre.contains('meditacion')) {
      return {'colors': [const Color(0xFF7B1FA2), const Color(0xFFBA68C8)], 'icon': Icons.self_improvement, 'label': 'MEDITACIÓN'};
    }
    if (nombre.contains('tribu')) {
      return {'colors': [const Color(0xFFF57C00), const Color(0xFFFFB74D)], 'icon': Icons.directions_walk, 'label': 'TRIBU ACTIVA'};
    }
    return {'colors': [const Color(0xFF1976D2), const Color(0xFF64B5F6)], 'icon': Icons.sports_gymnastics, 'label': 'EJERCICIO TERAPÉUTICO'};
  }

  Map<String, dynamic> _getMedicalVisuals() {
    return {'colors': [salufitGreen, const Color(0xFF4DB6AC)], 'icon': Icons.medical_services_outlined, 'label': 'CITA MÉDICA'};
  }

  // --- LÓGICA INTELIGENTE DE PRÓXIMA CLASE ---
  Future<Map<String, dynamic>?> _resolveNextClass(List<DocumentSnapshot> bookingDocs) async {
    try {
      final now = DateTime.now();
      final List<Map<String, dynamic>> candidatos = [];

      final List<Future<void>> futures = bookingDocs.map((doc) async {
        final bookingData = doc.data() as Map<String, dynamic>;
        final String? classId = bookingData['groupClassId'];
        
        if (classId != null && classId.isNotEmpty) {
          final classDoc = await FirebaseFirestore.instance.collection('groupClasses').doc(classId).get();
          if (classDoc.exists) {
            final classData = classDoc.data();
            if (classData != null && classData['fechaHoraInicio'] != null) {
              final DateTime fechaClase = (classData['fechaHoraInicio'] as Timestamp).toDate();
              if (fechaClase.isAfter(now)) {
                candidatos.add({
                  'nombre': classData['nombre'] ?? 'Clase',
                  'fecha': fechaClase,
                  'monitor': classData['monitor'] ?? '',
                  'id': classId
                });
              }
            }
          }
        }
      }).toList();

      await Future.wait(futures);
      if (candidatos.isEmpty) return null;
      candidatos.sort((a, b) => (a['fecha'] as DateTime).compareTo(b['fecha'] as DateTime));
      return candidatos.first;
    } catch (e) {
      debugPrint('Error calculando próxima clase: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SalufitScaffold(
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
          builder: (context, userSnapshot) {
            
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 1. OBTENCIÓN ROBUSTA DEL NOMBRE
            // Prioridad: 1. DB (nombreCompleto) -> 2. DB (nombre) -> 3. Auth (DisplayName) -> 4. "Usuario Salufit"
            String nombreMostrar = 'Usuario Salufit';
            String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              
              final String? nameFromDb = userData['nombreCompleto'] ?? userData['nombre'];
              
              if (nameFromDb != null && nameFromDb.isNotEmpty) {
                 nombreMostrar = nameFromDb;
              } else {
                 // Si en la DB está vacío, miramos en Auth
                 nombreMostrar = FirebaseAuth.instance.currentUser?.displayName ?? 'Usuario Salufit';
              }
              
              // Actualizamos el email desde la DB por si acaso es distinto (raro)
              if (userData.containsKey('email')) {
                userEmail = userData['email'];
              }
            } else {
               // Si el doc no existe, usamos Auth
               nombreMostrar = FirebaseAuth.instance.currentUser?.displayName ?? 'Usuario Salufit';
            }

            // Formateo visual (Solo primer nombre y Capitalizado)
            if (nombreMostrar.contains(' ')) nombreMostrar = nombreMostrar.split(' ')[0];
            if (nombreMostrar.isNotEmpty) {
                nombreMostrar = '${nombreMostrar[0].toUpperCase()}${nombreMostrar.substring(1).toLowerCase()}';
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CABECERA ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center, 
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bienvenido a Salufit,', style: TextStyle(fontSize: 18, color: salufitGreen, letterSpacing: 1, fontWeight: FontWeight.w500)),
                            Text(nombreMostrar, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: salufitGreen, height: 1.1)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Image.asset(
                          'assets/logo_salufit.png', 
                          width: 80, 
                          errorBuilder: (c,e,s) => Icon(Icons.person, size: 70, color: salufitGreen)
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 35), 

                  if (userEmail.isEmpty)
                     const Text('Completa tu perfil para ver tus reservas.', style: TextStyle(color: Colors.grey)),

                  // SECCIÓN 1: TU PRÓXIMA CLASE
                  if (userEmail.isNotEmpty)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where('userEmail', isEqualTo: userEmail)
                          .orderBy('fechaReserva', descending: true)
                          .limit(20) 
                          .snapshots(),
                      builder: (context, bookingsSnapshot) {
                        if (bookingsSnapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                        if (!bookingsSnapshot.hasData || bookingsSnapshot.data!.docs.isEmpty) return _buildEmptyCard('TU PRÓXIMA CLASE', 'Sin reservas próximas', Icons.fitness_center);

                        return FutureBuilder<Map<String, dynamic>?>(
                          future: _resolveNextClass(bookingsSnapshot.data!.docs),
                          builder: (context, nextClassSnapshot) {
                            if (nextClassSnapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                            if (!nextClassSnapshot.hasData || nextClassSnapshot.data == null) return _buildEmptyCard('TU PRÓXIMA CLASE', 'Sin reservas próximas', Icons.fitness_center);

                            final clase = nextClassSnapshot.data!;
                            final DateTime fecha = clase['fecha'];
                            final String nombreClase = clase['nombre'];
                            String dia = DateFormat('EEEE d', 'es').format(fecha);
                            dia = '${dia[0].toUpperCase()}${dia.substring(1)}';
                            final String hora = DateFormat('HH:mm').format(fecha);
                            final visual = _getClassVisuals(nombreClase);

                            return _buildDiscoverCard(title: 'TU PRÓXIMA CLASE', mainText: nombreClase, subText: '$dia a las $hora', colors: visual['colors'], icon: visual['icon']);
                          }
                        );
                      }
                    ),
                  
                  const SizedBox(height: 25),

                  // SECCIÓN 2: PRÓXIMA CITA MÉDICA
                  if (userEmail.isNotEmpty)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('appointments')
                          .where('patientEmail', isEqualTo: userEmail) 
                          .where('fechaHoraInicio', isGreaterThan: Timestamp.now())
                          .orderBy('fechaHoraInicio') 
                          .limit(5) 
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return _buildEmptyCard('CITA MÉDICA', 'Sin citas programadas', Icons.medical_services_outlined);
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyCard('CITA MÉDICA', 'Sin citas programadas', Icons.medical_services_outlined);
                        
                        final proximaCita = snapshot.data!.docs.first;
                        final data = proximaCita.data() as Map<String, dynamic>;
                        final DateTime fecha = (data['fechaHoraInicio'] as Timestamp).toDate();
                        String dia = DateFormat('EEEE d MMMM', 'es').format(fecha);
                        dia = '${dia[0].toUpperCase()}${dia.substring(1)}';
                        final String hora = DateFormat('H:mm').format(fecha);
                        final visualMed = _getMedicalVisuals();
                        final String especialidad = data['especialidad'] ?? data['tipo'] ?? 'Cita Médica';

                        return _buildDiscoverCard(title: 'PRÓXIMA CITA', mainText: especialidad, subText: '$dia a las $hora', colors: visualMed['colors'], icon: visualMed['icon']);
                      },
                    ),
                  const SizedBox(height: 50), 
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  Widget _buildDiscoverCard({required String title, required String mainText, required String subText, required List<Color> colors, required IconData icon}) {
    return Container(
      height: 120, 
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: colors[0].withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 5))]), 
      child: Stack(
        children: [
          Positioned(right: -15, bottom: -15, child: Icon(icon, size: 130, color: Colors.white.withValues(alpha: 0.15))), 
          Padding(
            padding: const EdgeInsets.all(20), 
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)), const SizedBox(height: 5), Text(mainText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 5), Row(children: [const Icon(Icons.access_time, color: Colors.white, size: 16), const SizedBox(width: 5), Text(subText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))])])
          )
        ]
      )
    );
  }

  Widget _buildEmptyCard(String title, String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20), 
      width: double.infinity, 
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)), 
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 10), Row(children: [Icon(icon, color: Colors.grey.shade300, size: 30), const SizedBox(width: 10), Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey))])])
    );
  }
}