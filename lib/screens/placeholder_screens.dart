import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
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
  Future<Map<String, dynamic>?> _findNextClassIntelligent(String userEmail) async {
    try {
      final now = DateTime.now();

      // 1. CONSULTA SIMPLE: Solo filtramos por email.
      final bookingsQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userEmail', isEqualTo: userEmail)
          .get();

      if (bookingsQuery.docs.isEmpty) return null;

      final List<Map<String, dynamic>> candidatos = [];

      // 2. Procesamos en memoria
      final List<Future<void>> futures = bookingsQuery.docs.map((doc) async {
        final bookingData = doc.data();
        final String? classId = bookingData['groupClassId'];
        
        if (classId != null) {
          final classDoc = await FirebaseFirestore.instance.collection('groupClasses').doc(classId).get();
          
          if (classDoc.exists) {
            final classData = classDoc.data();
            if (classData != null && classData['fechaHoraInicio'] != null) {
              final DateTime fechaClase = (classData['fechaHoraInicio'] as Timestamp).toDate();
              
              // Solo añadimos si es FUTURA
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

      // 3. Ordenamos AQUÍ
      candidatos.sort((a, b) => (a['fecha'] as DateTime).compareTo(b['fecha'] as DateTime));
      
      return candidatos.first;

    } catch (e) {
      debugPrint('Error recuperando próxima clase: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail == null) return const Center(child: Text('Error de sesión'));

    return SalufitScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userEmail).limit(1).get(),
                          builder: (context, snapshot) {
                            String nombreMostrar = 'Usuario'; 
                            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                              final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                              final String nombreCompleto = data['nombreCompleto'] ?? data['nombre'] ?? '';
                              if (nombreCompleto.isNotEmpty) {
                                nombreMostrar = nombreCompleto.split(' ')[0]; 
                                if (nombreMostrar.isNotEmpty) nombreMostrar = '${nombreMostrar[0].toUpperCase()}${nombreMostrar.substring(1).toLowerCase()}';
                              }
                            }
                            return Text(nombreMostrar, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: salufitGreen, height: 1.1));
                          },
                        ),
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

              // SECCIÓN 1: TU PRÓXIMA CLASE
              FutureBuilder<Map<String, dynamic>?>(
                future: _findNextClassIntelligent(userEmail),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                  }
                  
                  if (!snapshot.hasData || snapshot.data == null) {
                    return _buildEmptyCard('TU PRÓXIMA CLASE', 'Sin reservas próximas', Icons.fitness_center);
                  }

                  final clase = snapshot.data!;
                  final DateTime fecha = clase['fecha'];
                  final String nombreClase = clase['nombre'];
                  
                  String dia = DateFormat('EEEE d', 'es').format(fecha);
                  dia = '${dia[0].toUpperCase()}${dia.substring(1)}';
                  final String hora = DateFormat('HH:mm').format(fecha);
                  
                  final visual = _getClassVisuals(nombreClase);

                  return _buildDiscoverCard(
                    title: 'TU PRÓXIMA CLASE', 
                    mainText: nombreClase, 
                    subText: '$dia a las $hora', 
                    colors: visual['colors'], 
                    icon: visual['icon']
                  );
                }
              ),
              const SizedBox(height: 25),

              // SECCIÓN 2: PRÓXIMA CITA MÉDICA
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
                      child: SelectableText('⚠️ Error Citas: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                     return Container(
                       padding: const EdgeInsets.all(20), 
                       width: double.infinity, 
                       decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)), 
                       child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.calendar_today, color: Colors.grey), SizedBox(width: 10), Text('No tienes citas médicas próximas', style: TextStyle(color: Colors.grey))])
                     );
                  }
                  
                  final proximaCita = snapshot.data!.docs.first;
                  final restoDeCitas = snapshot.data!.docs.skip(1).toList();
                  final data = proximaCita.data() as Map<String, dynamic>;
                  final DateTime fecha = (data['fechaHoraInicio'] as Timestamp).toDate();
                  String dia = DateFormat('EEEE d MMMM', 'es').format(fecha);
                  dia = '${dia[0].toUpperCase()}${dia.substring(1)}';
                  final String hora = DateFormat('H:mm').format(fecha);
                  final visualMed = _getMedicalVisuals();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDiscoverCard(title: 'PRÓXIMA CITA', mainText: data['especialidad'] ?? 'Cita Médica', subText: '$dia a las $hora', colors: visualMed['colors'], icon: visualMed['icon']),
                      if (restoDeCitas.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text('Próximamente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
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
      ),
    );
  }

  Widget _buildDiscoverCard({required String title, required String mainText, required String subText, required List<Color> colors, required IconData icon}) {
    return Container(
      height: 120, 
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight), 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: colors[0].withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 5))]
      ), 
      child: Stack(
        children: [
          Positioned(right: -15, bottom: -15, child: Icon(icon, size: 130, color: Colors.white.withValues(alpha: 0.15))), 
          Padding(
            padding: const EdgeInsets.all(20), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)), 
                const SizedBox(height: 5), 
                Text(mainText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis), 
                const SizedBox(height: 5), 
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white, size: 16), 
                    const SizedBox(width: 5), 
                    Text(subText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))
                  ]
                )
              ]
            )
          )
        ]
      )
    );
  }

  Widget _buildSecondaryAppointmentCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final DateTime fecha = (data['fechaHoraInicio'] as Timestamp).toDate();
    final String diaCorto = DateFormat('dd/MM/yyyy').format(fecha);
    final String hora = DateFormat('H:mm').format(fecha);
    return Container(
      margin: const EdgeInsets.only(bottom: 10), 
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12), 
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), 
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8), 
            decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)), 
            child: Icon(Icons.calendar_today, size: 16, color: salufitGreen)
          ), 
          const SizedBox(width: 15), 
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(data['especialidad'] ?? 'Cita', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), 
                Text('$diaCorto - $hora', style: const TextStyle(color: Colors.grey, fontSize: 13))
              ]
            )
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)), 
          const SizedBox(height: 10), 
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade300, size: 30), 
              const SizedBox(width: 10), 
              Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey))
            ]
          )
        ]
      )
    );
  }
}