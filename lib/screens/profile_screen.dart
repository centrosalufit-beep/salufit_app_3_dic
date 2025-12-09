import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; 
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'login_screen.dart';
import 'class_list_screen.dart'; 
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
  bool _isSearchingClass = false; 

  // COLOR CORPORATIVO
  final Color salufitTeal = const Color(0xFF009688);

  // --- LÓGICA DE COLORES DE CLASES ---
  Map<String, dynamic> _getClassVisuals(String nombreClase) {
    final String nombre = nombreClase.toLowerCase();
    if (nombre.contains('entrenamiento')) {
      return {'colors': [const Color(0xFFD32F2F), const Color(0xFFE57373)], 'icon': Icons.fitness_center, 'textColor': Colors.red.shade900};
    }
    if (nombre.contains('meditación') || nombre.contains('meditacion')) {
      return {'colors': [const Color(0xFF7B1FA2), const Color(0xFFBA68C8)], 'icon': Icons.self_improvement, 'textColor': Colors.purple.shade900};
    }
    if (nombre.contains('tribu')) {
      return {'colors': [const Color(0xFFF57C00), const Color(0xFFFFB74D)], 'icon': Icons.directions_walk, 'textColor': Colors.orange.shade900};
    }
    return {'colors': [const Color(0xFF1976D2), const Color(0xFF64B5F6)], 'icon': Icons.sports_gymnastics, 'textColor': Colors.blue.shade900};
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchClassDetails(String classId) {
    return FirebaseFirestore.instance.collection('groupClasses').doc(classId).get();
  }

  Future<void> _abrirPrivacidad() async {
    if (!await launchUrl(_urlPrivacidad, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir la web')));
      }
    }
  }

  // --- FUNCIÓN DE ELIMINAR CUENTA (REQUISITO APPLE) ---
  Future<void> _eliminarCuenta() async {
    final bool? confirmar = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar Cuenta', style: TextStyle(color: Colors.red)),
        content: const Text('Esta acción es irreversible. Se borrarán tus datos personales y reservas.\n\n¿Estás seguro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(c, true), 
            child: const Text('SÍ, BORRAR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      )
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Borrar datos de Firestore
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      } catch (e) {
        debugPrint('No se pudo borrar el doc de Firestore (posiblemente falta permiso delete): $e');
      }
      
      // 2. Borrar autenticación
      await user.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta eliminada correctamente')));
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginScreen()), (r) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por seguridad, cierra sesión e inicia de nuevo para borrar la cuenta.')));
        }
      } else {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error general: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelarReserva(String bookingId, String classId, DateTime fechaClase) async {
    final DateTime ahora = DateTime.now();
    final Duration diferencia = fechaClase.difference(ahora);
    final int horasRestantes = diferencia.inHours;
    final bool esPenalizado = horasRestantes < 24;
    
    final bool? confirmar = await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: Text(esPenalizado ? '¡Atención!' : 'Cancelar Reserva', style: TextStyle(color: esPenalizado ? Colors.red : Colors.black)), 
        content: Text(esPenalizado ? 'Menos de 24h. Pierdes el token.' : 'Se devuelve el token.'), 
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('No')), 
          TextButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('Sí, cancelar'))
        ]
      )
    );
    
    if (confirmar != true) return;
    
    setState(() { _isLoading = true; });
    try {
      final response = await http.post(
        Uri.parse(_cancelFunctionUrl), 
        headers: {
          'Content-Type': 'application/json', 
          'Authorization': 'Bearer ${await FirebaseAuth.instance.currentUser?.getIdToken()}'
        }, 
        body: jsonEncode({
          'userId': widget.userId, 
          'bookingId': bookingId, 
          'classId': classId
        })
      );
      
      final data = jsonDecode(response.body);
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Error'), backgroundColor: Colors.red));
      }
    } catch (e) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); 
    } finally { 
      if (mounted) setState(() { _isLoading = false; }); 
    }
  }

  void _mostrarQrGrande() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('TU PASE DE ACCESO', style: TextStyle(color: salufitTeal, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 20),
              QrImageView(
                data: widget.userId, 
                version: QrVersions.auto, 
                size: 250, 
                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.circle, color: salufitTeal), 
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black87)
              ),
              const SizedBox(height: 20),
              const Text('Acerca el móvil al lector', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context), 
                style: ElevatedButton.styleFrom(backgroundColor: salufitTeal, foregroundColor: Colors.white), 
                child: const Text('CERRAR')
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _buscarYRedirigirClase(String keyword) async {
    setState(() { _isSearchingClass = true; });
    try {
      final now = DateTime.now();
      final querySnapshot = await FirebaseFirestore.instance
          .collection('groupClasses')
          .where('fechaHoraInicio', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('fechaHoraInicio')
          .limit(30) 
          .get();

      if (!mounted) return;

      DocumentSnapshot? claseEncontrada;
      for (var doc in querySnapshot.docs) {
        final String nombreClase = (doc['nombre'] ?? '').toString().toLowerCase();
        if (nombreClase.contains(keyword.toLowerCase())) {
          claseEncontrada = doc;
          break; 
        }
      }

      if (claseEncontrada != null) {
        final fechaClase = (claseEncontrada['fechaHoraInicio'] as Timestamp).toDate();
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ClassListScreen(userId: widget.userId, initialDate: fechaClase)));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay clases de este tipo programadas próximamente.')));
          Navigator.push(context, MaterialPageRoute(builder: (context) => ClassListScreen(userId: widget.userId)));
        }
      }
    } catch (e) {
      debugPrint('Error buscando clase: $e');
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => ClassListScreen(userId: widget.userId)));
    } finally {
      if (mounted) setState(() { _isSearchingClass = false; });
    }
  }

  // --- TARJETA INTELIGENTE ---
  Widget _buildSmartPromoCard(String? userEmail) {
    if (userEmail == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings')
          .where('userEmail', isEqualTo: userEmail)
          .orderBy('fechaReserva', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(); 

        final List<String> classIds = snapshot.data!.docs.map((d) => d['groupClassId'] as String).toList();

        if (classIds.isEmpty) {
          return _promoCardDesign(
            'REGALO MENSUAL EXCLUSIVO',
            'Tras estudiar tu perfil, te recomendamos usar tu sesión extra para entrenar en grupo y así mejorar tu fuerza.',
            Icons.fitness_center,
            'entrena' 
          );
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('groupClasses')
              .where(FieldPath.documentId, whereIn: classIds)
              .get(),
          builder: (context, classesSnap) {
            if (!classesSnap.hasData) return const SizedBox();

            final Set<String> tiposConsumidos = {};
            for (var doc in classesSnap.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final String nombre = (data['nombre'] ?? '').toString().toLowerCase();
              if (nombre.contains('entrena')) tiposConsumidos.add('entrenamiento');
              if (nombre.contains('terap')) tiposConsumidos.add('terapeutico');
              if (nombre.contains('medita')) tiposConsumidos.add('meditacion');
            }

            String mensajePersonalizado = '';
            String keywordBusqueda = ''; 
            IconData iconoSugerido = Icons.star;
            
            if (!tiposConsumidos.contains('meditacion')) {
              mensajePersonalizado = 'Tras haber estudiado tu perfil y conocer más sobre ti, te recomendamos que este mes disfrutes de tu sesión extra mensual para meditar en grupo y reducir tus niveles de estrés.';
              keywordBusqueda = 'medita'; 
              iconoSugerido = Icons.self_improvement;
            } else if (!tiposConsumidos.contains('terapeutico')) {
              mensajePersonalizado = 'Tras haber estudiado tu perfil y conocer más sobre ti, te recomendamos que este mes disfrutes de tu sesión extra mensual para mejorar el estado de tus articulaciones en una clase de ejercicio terapéutico grupal.';
              keywordBusqueda = 'terap'; 
              iconoSugerido = Icons.accessibility_new;
            } else if (!tiposConsumidos.contains('entrenamiento')) {
              mensajePersonalizado = 'Tras haber estudiado tu perfil y conocer más sobre ti, te recomendamos que este mes disfrutes de tu sesión extra mensual para entrenar en grupo y así mejorar tu fuerza.';
              keywordBusqueda = 'entrena'; 
              iconoSugerido = Icons.fitness_center;
            } else {
              mensajePersonalizado = 'Tras estudiar tu perfil, te recomendamos usar tu sesión extra para probar una nueva experiencia de salud y bienestar.';
              keywordBusqueda = 'entrena'; 
              iconoSugerido = Icons.auto_awesome;
            }

            return _promoCardDesign('REGALO MENSUAL EXCLUSIVO', mensajePersonalizado, iconoSugerido, keywordBusqueda);
          },
        );
      },
    );
  }

  Widget _promoCardDesign(String titulo, String cuerpo, IconData iconoClase, String keywordBusqueda) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200), 
      clipBehavior: Clip.hardEdge, 
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)], begin: Alignment.topLeft, end: Alignment.bottomRight), 
        borderRadius: BorderRadius.circular(25), 
        boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))]
      ),
      child: Stack(
        children: [
          Positioned(right: -20, bottom: -20, child: Transform.rotate(angle: -0.2, child: Icon(Icons.card_giftcard, size: 220, color: Colors.white.withValues(alpha: 0.25)))),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Text('SUGERENCIA PERSONALIZADA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0))),
                const SizedBox(height: 15),
                Text(titulo, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.brown.shade900, fontSize: 20, height: 1.1)),
                const SizedBox(height: 10),
                Text(cuerpo, style: TextStyle(color: Colors.brown.shade800, fontSize: 14, height: 1.4, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () => _buscarYRedirigirClase(keywordBusqueda), style: ElevatedButton.styleFrom(backgroundColor: Colors.brown.shade900, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 5, shadowColor: Colors.brown.withValues(alpha: 0.4)), child: _isSearchingClass ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.star, size: 18, color: Colors.amber), SizedBox(width: 8), Text('MEJORA TU CALIDAD DE VIDA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5))])))
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return const Center(child: Text('Error sesión'));

    return SalufitScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              
              // 1. CABECERA (CORREGIDO: Fallback para nombre)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
                builder: (context, snapshotUser) {
                  String nombreCompleto = 'Cargando...';
                  
                  if (snapshotUser.hasData && snapshotUser.data!.exists) { 
                      final d = snapshotUser.data!.data() as Map<String,dynamic>; 
                      // Intenta coger el nombre de la BD, si no hay, coge "Usuario"
                      final String? nameDb = d['nombreCompleto'] ?? d['nombre'];
                      
                      if (nameDb != null && nameDb.isNotEmpty) {
                        nombreCompleto = nameDb.toUpperCase();
                      } else {
                        // FALLBACK: Nombre de Google/Apple si la ficha está vacía
                        nombreCompleto = (FirebaseAuth.instance.currentUser?.displayName ?? 'USUARIO').toUpperCase();
                      }
                  } else {
                     // Si aún no carga, nombre de Google
                     nombreCompleto = (FirebaseAuth.instance.currentUser?.displayName ?? 'USUARIO').toUpperCase();
                  }

                  return Row(
                    children: [
                      Image.asset('assets/logo_salufit.png', width: 60, fit: BoxFit.contain, errorBuilder: (c,e,s) => Icon(Icons.person, size: 60, color: salufitTeal)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombreCompleto, style: TextStyle(fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3.0, color: salufitTeal, height: 1.0, shadows: [Shadow(offset: const Offset(1, 1), color: Colors.black.withValues(alpha: 0.1), blurRadius: 0)]), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              ),
              
              const SizedBox(height: 30),
              
              // 2. SESIONES Y QR
              SizedBox(
                height: 190, 
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6, 
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('passes').where('userEmail', isEqualTo: userEmail).limit(20).snapshots(),
                        builder: (context, snapshotPass) {
                           int tokens = 0; bool isActive = false;
                           if (snapshotPass.hasData && snapshotPass.data!.docs.isNotEmpty) {
                              final docs = snapshotPass.data!.docs;
                              // Filtramos en memoria igual que en class_list_screen
                              final bonoActivo = docs.where((d) => (d.data() as Map<String,dynamic>)['tokensRestantes'] > 0).firstOrNull;
                              if (bonoActivo != null) { tokens = (bonoActivo.data() as Map<String,dynamic>)['tokensRestantes']; isActive = true; }
                           }
                           final List<Color> cardColors = isActive ? [Colors.lightGreenAccent.shade700, Colors.tealAccent.shade700] : [Colors.deepOrangeAccent, Colors.orange.shade800]; 
                           return Container(
                              padding: const EdgeInsets.all(10),
                              clipBehavior: Clip.hardEdge, 
                              decoration: BoxDecoration(gradient: LinearGradient(colors: cardColors, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: cardColors[0].withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 5))]), 
                              child: Stack(
                                children: [
                                  Positioned(bottom: -50, right: -20, left: -20, child: Icon(Icons.bolt, size: 240, color: Colors.white.withValues(alpha: 0.18))),
                                  Positioned(top: 5, left: 5, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Text(isActive ? 'ACTIVO' : 'AGOTADO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)))),
                                  Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(height: 10), Text('$tokens', style: const TextStyle(color: Colors.white, fontSize: 70, fontWeight: FontWeight.w900, height: 1.0, shadows: [Shadow(color: Colors.black12, offset: Offset(2,2), blurRadius: 4)])), const Text('SESIONES', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 3.0))]))
                                ],
                              )
                            );
                        }
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 4, 
                      child: GestureDetector(
                        onTap: _mostrarQrGrande, 
                        child: Container(
                          padding: const EdgeInsets.all(4), 
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: salufitTeal.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 5))], border: Border.all(color: salufitTeal.withValues(alpha: 0.3), width: 1.5)), 
                          child: Column(
                            children: [
                              Container(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), decoration: BoxDecoration(color: salufitTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Icon(Icons.qr_code_scanner, size: 12, color: salufitTeal), const SizedBox(width: 4), Text('ACCESO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: salufitTeal, letterSpacing: 0.5))])),
                              Expanded(child: Center(child: Stack(alignment: Alignment.center, children: [QrImageView(data: widget.userId, version: QrVersions.auto, padding: const EdgeInsets.all(10), eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.circle, color: salufitTeal), dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black87)), Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]), child: Icon(Icons.fitness_center, size: 14, color: salufitTeal))]))),
                              const Text('Toca para ampliar', style: TextStyle(fontSize: 8, color: Colors.grey)),
                              const SizedBox(height: 6),
                            ],
                          )
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              _buildSmartPromoCard(userEmail),

              const SizedBox(height: 35),
              
              Text('MIS RESERVAS RECIENTES', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: salufitTeal, fontFamily: 'serif', letterSpacing: 1.0)), 
              const SizedBox(height: 15),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('bookings').where('userEmail', isEqualTo: userEmail).orderBy('fechaReserva', descending: true).limit(10).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('No has hecho ninguna reserva todavía.', style: TextStyle(color: Colors.grey)));
                  
                  final reservas = snapshot.data!.docs;
                  return ListView.separated(
                    shrinkWrap: true, 
                    physics: const NeverScrollableScrollPhysics(), 
                    itemCount: reservas.length, 
                    separatorBuilder: (context, index) => const SizedBox(height: 15), 
                    itemBuilder: (context, index) {
                      final doc = reservas[index]; final reserva = doc.data() as Map<String, dynamic>; final bookingId = doc.id;
                      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        future: _fetchClassDetails(reserva['groupClassId']),
                        builder: (context, classSnapshot) {
                          String nombreClase = 'Cargando...'; String fechaTexto = ''; String horaTexto = ''; DateTime? fechaClaseReal;
                          if (classSnapshot.hasData && classSnapshot.data!.exists) {
                            final classData = classSnapshot.data!.data()!; nombreClase = classData['nombre'] ?? 'Clase';
                            if (classData['fechaHoraInicio'] != null) { final Timestamp ts = classData['fechaHoraInicio']; fechaClaseReal = ts.toDate(); String diaSemana = DateFormat('EEEE d', 'es').format(fechaClaseReal); if (diaSemana.isNotEmpty) diaSemana = '${diaSemana[0].toUpperCase()}${diaSemana.substring(1)}'; fechaTexto = diaSemana; horaTexto = DateFormat('HH:mm').format(fechaClaseReal); }
                          } else if (classSnapshot.connectionState == ConnectionState.done) { nombreClase = 'Clase eliminada'; }
                          final visual = _getClassVisuals(nombreClase);
                          return Container(
                            height: 100, 
                            decoration: BoxDecoration(gradient: LinearGradient(colors: visual['colors'], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: (visual['colors'][0] as Color).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))]), 
                            child: Stack(
                              children: [
                                Positioned(right: -15, bottom: -15, child: Icon(visual['icon'], size: 100, color: Colors.white.withValues(alpha: 0.15))), 
                                Padding(padding: const EdgeInsets.all(15.0), child: Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.access_time, color: Colors.white, size: 16), const SizedBox(height: 2), Text(horaTexto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))])), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(nombreClase, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis), Text(fechaTexto, style: const TextStyle(color: Colors.white70, fontSize: 14))])), if (!_isLoading) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white, size: 28), onPressed: () => _cancelarReserva(bookingId, reserva['groupClassId'], fechaClaseReal ?? DateTime.now().add(const Duration(days: 30)))) else const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))]))
                              ]
                            )
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
              
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () { Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false); }, icon: const Icon(Icons.logout, color: Colors.orange), label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.orange)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(15), side: const BorderSide(color: Colors.orange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
              const SizedBox(height: 10),
              Center(child: TextButton(onPressed: _eliminarCuenta, child: const Text('Eliminar mi cuenta definitivamente', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 10),
              Center(child: TextButton(onPressed: _abrirPrivacidad, child: const Text('Política de Privacidad', style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline, fontSize: 12)))),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}