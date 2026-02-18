import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';
import 'package:salufit_app/features/home/presentation/home_providers.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({required this.userId, super.key});
  final String userId;

  @override
  ConsumerState<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  final Color salufitTeal = const Color(0xFF009688);
  bool _isActionLoading = false;

  Future<void> _ejecutarCancelacionCloud(String bookingId, String nombre, DateTime fechaClase) async {
    final ahora = DateTime.now();
    final diff = fechaClase.difference(ahora).inHours;
    final esPenalizado = diff < 24;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (c) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.white.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(esPenalizado ? '⚠️ ATENCIÓN' : '¿ANULAR CITA?', 
            style: TextStyle(fontWeight: FontWeight.w900, color: esPenalizado ? Colors.red : Colors.black)),
          content: Text('Clase: $nombre\nFecha: ${DateFormat('EEEE d', 'es').format(fechaClase)}\n\n${esPenalizado ? "Faltan menos de 24h: Se consumirá el token." : "Recuperarás tu token automáticamente."}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('VOLVER')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: esPenalizado ? Colors.red : Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('CONFIRMAR'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true) return;
    setState(() => _isActionLoading = true);

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final url = Uri.parse('https://cancelarreserva-6cmp56xv3a-uc.a.run.app'); 
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'bookingId': bookingId}),
      );

      // --- CORRECCIÓN DE ERROR 1: ASIGNACIÓN DE MAPA ---
      final Map<String, dynamic> responseData = Map<String, dynamic>.from(jsonDecode(response.body) as Map);

      if (response.statusCode == 200) {
        // --- CORRECCIÓN DE ERROR 2: ASIGNACIÓN DE BOOLEANO ---
        final bool fueReembolsado = responseData['tokenDevuelto'] == true;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(fueReembolsado 
              ? '✅ Reserva anulada y token devuelto' 
              : '⚠️ Reserva anulada (token no recuperado por falta de tiempo)'),
            backgroundColor: fueReembolsado ? Colors.green : Colors.orange.shade900,
            duration: const Duration(seconds: 4),
          ));
        }
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _mostrarQrGrande() {
    showDialog<void>(
      context: context,
      builder: (c) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Dialog(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('PASAPORTE SALUFIT', style: TextStyle(color: salufitTeal, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 30),
                QrImageView(
                  data: widget.userId,
                  size: 220,
                  eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.circle, color: salufitTeal),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black87),
                ),
                const SizedBox(height: 25),
                const Text('Escanea en el centro para el check-in', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 25),
                TextButton(onPressed: () => Navigator.pop(c), child: const Text('CERRAR', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final passesStream = FirebaseFirestore.instance.collection('passes').where('userId', isEqualTo: widget.userId).where('activo', isEqualTo: true).snapshots();
    final bookingsStream = FirebaseFirestore.instance.collection('bookings').where('userId', isEqualTo: widget.userId).snapshots();

    return profileAsync.when(
      loading: () => const SalufitScaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => SalufitScaffold(body: Center(child: Text('Error: $e'))),
      data: (snapshot) {
        final userData = snapshot.data();
        final String name = (userData?['nombre'] ?? "AXEL").toString().toUpperCase();

        return SalufitScaffold(
          backgroundColor: const Color(0xFFF8FAF9),
          body: SafeArea(
            child: _isActionLoading 
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildHeader(name),
                    SliverToBoxAdapter(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: passesStream,
                        builder: (context, snap) {
                          int totalTokens = 0;
                          if (snap.hasData) {
                            for (var d in snap.data!.docs) {
                              totalTokens += (d.data() as Map<String, dynamic>).safeInt('tokensRestantes');
                            }
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            child: Row(children: [
                              Expanded(child: _buildTokenCard(totalTokens)),
                              const SizedBox(width: 15),
                              Expanded(child: _buildQrCard()),
                            ]),
                          );
                        }
                      ),
                    ),
                    SliverToBoxAdapter(child: GoldenGiftCard(userId: widget.userId)),
                    _buildSectionTitle('MIS PRÓXIMAS RESERVAS'),
                    StreamBuilder<QuerySnapshot>(
                      stream: bookingsStream,
                      builder: (context, snap) {
                        if (!snap.hasData || snap.data!.docs.isEmpty) {
                          return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No tienes reservas próximas'))));
                        }
                        final bookings = snap.data!.docs;
                        return SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final bData = bookings[index].data() as Map<String, dynamic>;
                            final classId = bData.safeString('groupClassId');
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('groupClasses').doc(classId).get(),
                              builder: (context, classSnap) {
                                if (!classSnap.hasData) return const SizedBox();
                                final cData = classSnap.data!.data() as Map<String, dynamic>?;
                                if (cData == null) return const SizedBox();
                                final String nombre = cData.safeString('nombre').toUpperCase();
                                final DateTime fecha = cData.safeDateTime('fechaHoraInicio');
                                if (fecha.isBefore(DateTime.now().subtract(const Duration(hours: 1)))) return const SizedBox();
                                return _buildBookingCard(bookings[index].id, nombre, fecha);
                              },
                            );
                          }, childCount: bookings.length),
                        );
                      }
                    ),
                    _buildSectionTitle('GESTIÓN DE CUENTA'),
                    SliverToBoxAdapter(child: _buildLogoutButton()),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
                  ],
                ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(25, 30, 20, 12),
      child: Text(title, style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 2)),
    ),
  );

  Widget _buildHeader(String name) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontFamily: 'serif', fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF009688))),
          const Text('MI PERFIL SALUFIT', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );

  Widget _buildTokenCard(int tokens) => Container(
    height: 140,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [const Color(0xFF80CBC4).withValues(alpha: 0.8), const Color(0xFF4DB6AC)]),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))],
    ),
    child: Stack(
      children: [
        Positioned(right: -10, top: -10, child: Icon(Icons.bolt, size: 100, color: Colors.white.withValues(alpha: 0.15))),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.generating_tokens, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Expanded(child: FittedBox(child: Text('$tokens', style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Colors.white, height: 1)))),
              const Text('TOKENS DISPONIBLES', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildQrCard() => InkWell(
    onTap: _mostrarQrGrande,
    child: Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF7986CB).withValues(alpha: 0.8), const Color(0xFF3F51B5)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 55, color: Colors.white),
          SizedBox(height: 8),
          Text('ACCESO AL CENTRO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white70)),
        ],
      ),
    ),
  );

  Widget _buildBookingCard(String bId, String nombre, DateTime fecha) {
    final n = nombre.toLowerCase();
    List<Color> colors = [const Color(0xFF80CBC4), const Color(0xFF009688)];
    IconData icon = Icons.medical_services;

    if (n.contains('entrena')) {
      colors = [const Color(0xFFEF9A9A), const Color(0xFFD32F2F)];
      icon = Icons.fitness_center;
    } else if (n.contains('medita')) {
      colors = [const Color(0xFF7986CB), const Color(0xFF3F51B5)];
      icon = Icons.self_improvement;
    }

    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: colors[1].withValues(alpha: 0.2), blurRadius: 8)]),
      child: ListTile(
        leading: Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 35),
        title: Text(nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
        subtitle: Text(DateFormat('EEEE d - HH:mm', 'es').format(fecha), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        trailing: IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.white70), onPressed: () => _ejecutarCancelacionCloud(bId, nombre, fecha)),
      ),
    );
  }

  Widget _buildLogoutButton() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
    child: TextButton.icon(
      onPressed: () => ref.read(authServiceProvider).signOut(),
      style: TextButton.styleFrom(foregroundColor: Colors.black87, minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      icon: const Icon(Icons.power_settings_new, size: 20),
      label: const Text('CERRAR SESIÓN', style: TextStyle(fontWeight: FontWeight.w900)),
    ),
  );
}

class GoldenGiftCard extends ConsumerStatefulWidget {
  const GoldenGiftCard({required this.userId, super.key});
  final String userId;
  @override
  ConsumerState<GoldenGiftCard> createState() => _GoldenGiftCardState();
}

class _GoldenGiftCardState extends ConsumerState<GoldenGiftCard> {
  bool _isOpened = false;
  @override
  void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('gift_${DateTime.now().month}') ?? false) setState(() => _isOpened = true);
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 500),
      crossFadeState: _isOpened ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: GestureDetector(
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('gift_${DateTime.now().month}', true);
          setState(() => _isOpened = true);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]), borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 12)]),
          child: const Row(children: [Icon(Icons.card_giftcard, color: Colors.white), SizedBox(width: 15), Text('TIENES UN REGALO MENSUAL', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.brown)), Spacer(), Icon(Icons.chevron_right, color: Colors.white)]),
        ),
      ),
      secondChild: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.amber, width: 2)),
          child: Column(children: [
            const Text(' BENEFICIO EXCLUSIVO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.percent, color: Color(0xFF009688)), 
              title: const Text('25€ DTO. NESA/INDIBA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), 
              onTap: () => launchUrl(Uri.parse('https://wa.me/34629011055?text=Hola!%20Me%20gustaría%20disfrutar%20del%20bono%20de%2025€'), mode: LaunchMode.externalApplication)
            ),
            const Divider(height: 30),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Color(0xFF009688)), 
              title: const Text('1 TOKEN EXTRA REGALO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), 
              onTap: () => ref.read(homeTabProvider.notifier).setTab(1)
            ),
          ]),
        ),
      ),
    );
  }
}
