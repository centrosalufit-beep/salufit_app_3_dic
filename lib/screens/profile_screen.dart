import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; 
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart'; 

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

  MaterialColor _getColorPorClase(String nombreClase) {
    String nombre = nombreClase.toLowerCase(); 
    if (nombre.contains('entrenamiento')) return Colors.red; 
    if (nombre.contains('meditación') || nombre.contains('meditacion')) return Colors.blueGrey; 
    return Colors.blue; 
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

    String tituloDialogo = esPenalizado ? "¡Atención! (Faltan ${horasRestantes}h)" : "Cancelar Reserva";
    String mensajeDialogo = esPenalizado
        ? "Quedan menos de 24h para el inicio.\n\nSi cancelas ahora, EL TOKEN SE CONSUMIRÁ IGUAL y no se te devolverá.\n\n¿Estás seguro?"
        : "Faltan más de 24h (${horasRestantes}h).\n\nEl token se te devolverá a tu cuenta.";
    
    Color colorBoton = esPenalizado ? Colors.red : Colors.blue;
    String textoBoton = esPenalizado ? "Sí, asumir penalización" : "Sí, cancelar reserva";

    bool? confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tituloDialogo, style: TextStyle(color: esPenalizado ? Colors.red : Colors.black, fontWeight: FontWeight.bold)),
        content: Text(mensajeDialogo),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No, volver")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text(textoBoton, style: TextStyle(color: colorBoton, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
        Uri.parse(_cancelFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'bookingId': bookingId,
          'classId': classId,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        bool tokenDevuelto = data['tokenDevuelto'] ?? false;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: tokenDevuelto ? Colors.green : Colors.orange, duration: const Duration(seconds: 4)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Error al cancelar'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = 'es';
    String idConCeros = widget.userId.padLeft(6, '0');
    String idSinCeros = widget.userId.replaceFirst(RegExp(r'^0+'), '');
    List<dynamic> posiblesIds = [idConCeros, idSinCeros];
    if (int.tryParse(idSinCeros) != null) posiblesIds.add(int.parse(idSinCeros));
    
    DateTime now = DateTime.now();
    int mesActual = now.month;
    int anioActual = now.year;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Mi Perfil", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(idConCeros).snapshots(),
              builder: (context, snapshotUser) {
                String nombreMostrado = "Usuario ${widget.userId}";
                String nombreCompleto = "Cargando...";
                if (snapshotUser.hasData && snapshotUser.data!.exists) {
                  var userData = snapshotUser.data!.data() as Map<String, dynamic>;
                  nombreCompleto = userData['nombreCompleto'] ?? userData['nombre'] ?? 'Usuario';
                  nombreMostrado = nombreCompleto;
                }
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('passes')
                      .where('userId', whereIn: posiblesIds)
                      .where('mes', isEqualTo: mesActual)
                      .where('anio', isEqualTo: anioActual)
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshotPass) {
                     int tokens = 0;
                     bool isActive = false;
                     if (snapshotPass.hasData && snapshotPass.data!.docs.isNotEmpty) {
                        var passData = snapshotPass.data!.docs.first.data() as Map<String, dynamic>;
                        tokens = passData['tokensRestantes'] ?? 0;
                        isActive = true;
                     }
                     return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(radius: 30, backgroundColor: Colors.blue.shade100, child: Icon(Icons.person, size: 35, color: Colors.blue.shade800)),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Bienvenido/a,", style: TextStyle(color: Colors.grey)),
                                  Text(nombreMostrado, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 2),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 30),
                        Container(
                          width: double.infinity,
                          height: 180,
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: isActive ? [const Color(0xFF4481EB), const Color(0xFF04BEFE)] : [Colors.grey, Colors.grey.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [BoxShadow(color: isActive ? Colors.blue.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 10))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.fitness_center, color: Colors.white70, size: 30),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                                    child: Text(isActive ? "ACTIVO" : "INACTIVO", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  )
                                ],
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
                                      const Text("Tokens\nDisponibles", style: TextStyle(color: Colors.white70, height: 1.1)),
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                );
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  const Text("Tu Pase de Acceso", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))]),
                    child: QrImageView(data: widget.userId, version: QrVersions.auto, size: 180.0, 
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text("ID: ${widget.userId}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Mis Reservas Recientes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bookings').where('userId', isEqualTo: widget.userId).orderBy('fechaReserva', descending: true).limit(10).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text("No has hecho ninguna reserva todavía.");
                var reservas = snapshot.data!.docs;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reservas.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    var doc = reservas[index];
                    var reserva = doc.data() as Map<String, dynamic>;
                    var bookingId = doc.id;
                    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: _fetchClassDetails(reserva['groupClassId']),
                      builder: (context, classSnapshot) {
                        String nombreClase = "Cargando Clase...";
                        String fechaReservaTexto = "...";
                        MaterialColor colorTematico = Colors.grey;
                        DateTime? fechaClaseReal;
                        if (classSnapshot.hasData && classSnapshot.data!.exists) {
                          var classData = classSnapshot.data!.data()!;
                          nombreClase = classData['nombreClase'] ?? 'Clase';
                          colorTematico = _getColorPorClase(nombreClase);
                          if (classData['fechaHoraInicio'] != null) {
                            Timestamp ts = classData['fechaHoraInicio'];
                            fechaClaseReal = ts.toDate();
                            String diaSemana = DateFormat('EEEE d MMMM', 'es').format(fechaClaseReal);
                            String hora = DateFormat('H:mm').format(fechaClaseReal);
                            if (diaSemana.isNotEmpty) diaSemana = "${diaSemana[0].toUpperCase()}${diaSemana.substring(1)}";
                            fechaReservaTexto = "$diaSemana a las $hora";
                          }
                        } else if (classSnapshot.connectionState == ConnectionState.done) {
                           nombreClase = "Clase eliminada";
                        }
                        return Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 5, offset: const Offset(0, 2))]),
                          child: ListTile(
                            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: colorTematico.shade50, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.calendar_month, color: colorTematico)),
                            title: Text(nombreClase, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(fechaReservaTexto),
                            trailing: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _cancelarReserva(bookingId, reserva['groupClassId'], fechaClaseReal ?? DateTime.now().add(const Duration(days: 30))),
                                ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(15), side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
            const SizedBox(height: 20),
            // --- ENLACE PRIVACIDAD EN PERFIL ---
            Center(
              child: TextButton(
                onPressed: _abrirPrivacidad,
                child: const Text("Política de Privacidad", style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}