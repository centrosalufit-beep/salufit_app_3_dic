import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; 
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'login_screen.dart'; 
import '../widgets/salufit_scaffold.dart'; 

class ProfileScreen extends StatefulWidget { 
  final String userId;
  const ProfileScreen({super.key, required this.userId});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _cancelFunctionUrl = 'https://us-central1-salufitnewapp.cloudfunctions.net/cancelarReserva';
  final Uri _urlPrivacidad = Uri.parse('https://www.centrosalufit.com/politica-de-privacidad'); 
  bool _isLoading = false;

  Map<String, dynamic> _getClassVisuals(String nombreClase) {
    String nombre = nombreClase.toLowerCase();
    if (nombre.contains('entrenamiento')) return {'colors': [const Color(0xFFD32F2F), const Color(0xFFE57373)], 'icon': Icons.fitness_center, 'textColor': Colors.red.shade900};
    if (nombre.contains('meditación') || nombre.contains('meditacion')) return {'colors': [const Color(0xFF7B1FA2), const Color(0xFFBA68C8)], 'icon': Icons.self_improvement, 'textColor': Colors.purple.shade900};
    if (nombre.contains('tribu')) return {'colors': [const Color(0xFFF57C00), const Color(0xFFFFB74D)], 'icon': Icons.directions_walk, 'textColor': Colors.orange.shade900};
    return {'colors': [const Color(0xFF1976D2), const Color(0xFF64B5F6)], 'icon': Icons.sports_gymnastics, 'textColor': Colors.blue.shade900};
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchClassDetails(String classId) {
    return FirebaseFirestore.instance.collection('groupClasses').doc(classId).get();
  }

  Future<void> _abrirPrivacidad() async {
    if (!await launchUrl(_urlPrivacidad, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo abrir la web")));
    }
  }

  Future<void> _cancelarReserva(String bookingId, String classId, DateTime fechaClase) async {
    final DateTime ahora = DateTime.now();
    final Duration diferencia = fechaClase.difference(ahora);
    final int horasRestantes = diferencia.inHours;
    final bool esPenalizado = horasRestantes < 24;
    bool? confirmar = await showDialog(context: context, builder: (context) => AlertDialog(title: Text(esPenalizado ? "¡Atención!" : "Cancelar Reserva", style: TextStyle(color: esPenalizado ? Colors.red : Colors.black)), content: Text(esPenalizado ? "Menos de 24h. Pierdes el token." : "Se devuelve el token."), actions: [TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text("No")), TextButton(onPressed: ()=>Navigator.pop(context,true), child: const Text("Sí, cancelar"))]));
    if (confirmar != true) return;
    setState(() { _isLoading = true; });
    try {
      final response = await http.post(Uri.parse(_cancelFunctionUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'userId': widget.userId, 'bookingId': bookingId, 'classId': classId}));
      final data = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
      else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Error'), backgroundColor: Colors.red));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); } 
    finally { if (mounted) setState(() { _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return const Center(child: Text("Error sesión"));

    return SalufitScaffold(
      appBar: AppBar(title: const Text("Mi Perfil", style: TextStyle(color: Colors.black)), backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.black), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 2. PERFIL
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userEmail).limit(1).snapshots(),
              builder: (context, snapshotUser) {
                String nombreMostrado = "Usuario ${widget.userId}";
                String nombreCompleto = "Cargando...";
                if (snapshotUser.hasData && snapshotUser.data!.docs.isNotEmpty) { 
                    var d = snapshotUser.data!.docs.first.data() as Map<String,dynamic>; 
                    nombreCompleto = d['nombreCompleto']??d['nombre']??'Usuario'; 
                    nombreMostrado = nombreCompleto; 
                }
                
                // 3. BONOS
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('passes')
                      .where('userEmail', isEqualTo: userEmail) 
                      .limit(20) 
                      .snapshots(),
                  builder: (context, snapshotPass) {
                     int tokens = 0; bool isActive = false;
                     if (snapshotPass.hasError) return Container(padding: const EdgeInsets.all(10), color: Colors.red.shade50, child: Text("Error Bonos: ${snapshotPass.error}", style: const TextStyle(color: Colors.red, fontSize: 10)));

                     if (snapshotPass.hasData && snapshotPass.data!.docs.isNotEmpty) {
                        var docs = snapshotPass.data!.docs;
                        var bonoActivo = docs.where((d) => (d.data() as Map<String,dynamic>)['tokensRestantes'] > 0).firstOrNull;
                        if (bonoActivo != null) { tokens = (bonoActivo.data() as Map<String,dynamic>)['tokensRestantes']; isActive = true; }
                     }

                     // --- LÓGICA VISUAL DE LA TARJETA (NUEVA) ---
                     // Si hay tokens: Verde Eléctrico. Si no: Naranja Alerta.
                     List<Color> cardColors = isActive 
                        ? [Colors.lightGreenAccent.shade700, Colors.tealAccent.shade700] // Verde Eléctrico
                        : [Colors.deepOrangeAccent, Colors.orange.shade800]; // Naranja Alerta
                     
                     // Icono Hoja (Spa) o Alerta si está a cero
                     IconData cardIcon = isActive ? Icons.spa : Icons.warning_amber_rounded;
                     String statusText = isActive ? "ACTIVO" : "AGOTADO";

                     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [CircleAvatar(radius: 30, backgroundColor: Colors.blue.shade100, child: Icon(Icons.person, size: 35, color: Colors.blue.shade800)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Bienvenido/a,", style: TextStyle(color: Colors.grey)), Text(nombreMostrado, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 2)]))]),
                        const SizedBox(height: 30),
                        
                        // TARJETA DE TOKENS REDISEÑADA
                        Container(
                          width: double.infinity, 
                          height: 180, 
                          padding: const EdgeInsets.all(25), 
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: cardColors, 
                              begin: Alignment.topLeft, 
                              end: Alignment.bottomRight
                            ), 
                            borderRadius: BorderRadius.circular(25), 
                            boxShadow: [BoxShadow(color: cardColors[0].withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 10))]
                          ), 
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                children: [
                                  Icon(cardIcon, color: Colors.white.withOpacity(0.8), size: 35), // ICONO HOJA
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), 
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), 
                                    child: Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
                                  )
                                ]
                              ), 
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start, 
                                children: [
                                  Text(nombreCompleto, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis), 
                                  const SizedBox(height: 5), 
                                  Row(
                                    children: [
                                      Text("$tokens", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)), 
                                      const SizedBox(width: 10), 
                                      const Text("Tokens\nDisponibles", style: TextStyle(color: Colors.white70, height: 1.1))
                                    ]
                                  )
                                ]
                              )
                            ]
                          )
                        ),
                      ]);
                  }
                );
              },
            ),
            const SizedBox(height: 20),
            Center(child: Column(children: [const Text("Tu Pase de Acceso", style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 10), Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))]), child: QrImageView(data: widget.userId, version: QrVersions.auto, size: 180.0, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black), dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black))), const SizedBox(height: 5), Text("ID: ${widget.userId}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1))])),
            const SizedBox(height: 30),
            const Text("Mis Reservas Recientes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings').where('userEmail', isEqualTo: userEmail).orderBy('fechaReserva', descending: true).limit(10).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Text("Error Reservas: ${snapshot.error}", style: const TextStyle(color: Colors.red));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text("No has hecho ninguna reserva todavía.");
                var reservas = snapshot.data!.docs;
                return ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: reservas.length, separatorBuilder: (context, index) => const SizedBox(height: 15), itemBuilder: (context, index) {
                    var doc = reservas[index]; var reserva = doc.data() as Map<String, dynamic>; var bookingId = doc.id;
                    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: _fetchClassDetails(reserva['groupClassId']),
                      builder: (context, classSnapshot) {
                        String nombreClase = "Cargando..."; String fechaTexto = ""; String horaTexto = ""; DateTime? fechaClaseReal;
                        if (classSnapshot.hasData && classSnapshot.data!.exists) {
                          var classData = classSnapshot.data!.data()!; nombreClase = classData['nombre'] ?? 'Clase';
                          if (classData['fechaHoraInicio'] != null) { Timestamp ts = classData['fechaHoraInicio']; fechaClaseReal = ts.toDate(); String diaSemana = DateFormat('EEEE d', 'es').format(fechaClaseReal); if (diaSemana.isNotEmpty) diaSemana = "${diaSemana[0].toUpperCase()}${diaSemana.substring(1)}"; fechaTexto = diaSemana; horaTexto = DateFormat('HH:mm').format(fechaClaseReal); }
                        } else if (classSnapshot.connectionState == ConnectionState.done) { nombreClase = "Clase eliminada"; }
                        var visual = _getClassVisuals(nombreClase);
                        return Container(height: 100, decoration: BoxDecoration(gradient: LinearGradient(colors: visual['colors'], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: (visual['colors'][0] as Color).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]), child: Stack(children: [Positioned(right: -15, bottom: -15, child: Icon(visual['icon'], size: 100, color: Colors.white.withOpacity(0.15))), Padding(padding: const EdgeInsets.all(15.0), child: Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.access_time, color: Colors.white, size: 16), const SizedBox(height: 2), Text(horaTexto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))])), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(nombreClase, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis), Text(fechaTexto, style: const TextStyle(color: Colors.white70, fontSize: 14))])), if (!_isLoading) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white, size: 28), onPressed: () => _cancelarReserva(bookingId, reserva['groupClassId'], fechaClaseReal ?? DateTime.now().add(const Duration(days: 30)))) else const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))]))]));
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () { Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false); }, icon: const Icon(Icons.logout, color: Colors.red), label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(15), side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
            const SizedBox(height: 20),
            Center(child: TextButton(onPressed: _abrirPrivacidad, child: const Text("Política de Privacidad", style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline, fontSize: 12)))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}