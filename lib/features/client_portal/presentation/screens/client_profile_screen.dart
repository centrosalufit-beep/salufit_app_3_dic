import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/auth/presentation/login_screen.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';
import 'package:salufit_app/features/bookings/data/class_repository.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({required this.userId, super.key});
  final String userId;

  @override
  ConsumerState<ClientProfileScreen> createState() =>
      _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  static const _salufitTeal = Color(0xFF00796B);
  bool _isDeleting = false;
  bool _isCancelling = false;

  // --- Lógica de Herencia de Color por Categoría ---
  List<Color> _getCategoryGradient(String name) {
    final lowerName = name.toLowerCase();

    // Entrenamiento / Fuerza / HIIT (Rojos/Naranjas)
    if (lowerName.contains('entrenamiento') ||
        lowerName.contains('fuerza') ||
        lowerName.contains('hiit')) {
      return [const Color(0xFFEF5350), const Color(0xFFD32F2F)];
    }

    // Ejercicio Terapéutico / Salud (Azules)
    if (lowerName.contains('terapéutico') ||
        lowerName.contains('terapeutico') ||
        lowerName.contains('salud')) {
      return [const Color(0xFF42A5F5), const Color(0xFF1976D2)];
    }

    // Pilates / Yoga / Bienestar (Teal/Verdes)
    if (lowerName.contains('pilates') || lowerName.contains('yoga')) {
      return [const Color(0xFF26A69A), const Color(0xFF00695C)];
    }

    // Default (Salufit Teal)
    return [const Color(0xFF00BFA5), const Color(0xFF00796B)];
  }

  Future<void> _cancelarReserva({
    required String bookingId,
    required String classId,
    required DateTime fecha,
  }) async {
    final horas = fecha.difference(DateTime.now()).inHours;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar reserva?'),
        content: Text(
          horas < 24
              ? 'Quedan menos de 24h. Si cancelas ahora, no se devolverá el bono según la política del centro.'
              : 'Se devolverá el bono a tu cuenta automáticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('VOLVER'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('CANCELAR RESERVA'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      setState(() => _isCancelling = true);
      try {
        await ref.read(classRepositoryProvider).cancelarReserva(
              userId: widget.userId,
              bookingId: bookingId,
              classId: classId,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reserva cancelada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on Exception catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cancelar: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isCancelling = false);
      }
    }
  }

  Future<void> _eliminarCuenta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta definitivamente'),
        content: const Text(
          'Esta acción es irreversible. Se borrarán tus datos de salud, citas y bonos activos de forma permanente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('SÍ, ELIMINAR TODO'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await ref.read(authServiceProvider).deleteAccount();
      if (mounted) {
        await Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        final msg = e.toString();
        final isAuthError = msg.contains('recent-login');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAuthError
                  ? 'Por seguridad, debes cerrar sesión e iniciarla de nuevo antes de borrar la cuenta.'
                  : 'Error: $e',
            ),
            backgroundColor: isAuthError ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarQrGrande() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ACCESO PROFESIONAL',
              style:
                  TextStyle(fontWeight: FontWeight.w900, color: _salufitTeal),
            ),
            const SizedBox(height: 20),
            QrImageView(
              data: widget.userId,
              size: 250,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.circle,
                color: _salufitTeal,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Muestra este código al staff para asistencia manual.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return SalufitScaffold(
      body: SafeArea(
        child: _isDeleting
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                children: [
                  userProfileAsync.when(
                    loading: () => const SizedBox(height: 80),
                    error: (_, __) => const SizedBox(height: 80),
                    data: (doc) {
                      final data = doc.data() ?? {};
                      final name = data
                          .safeString(
                            'nombreCompleto',
                            defaultValue: data.safeString(
                              'nombre',
                              defaultValue: 'USUARIO',
                            ),
                          )
                          .toUpperCase();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: _salufitTeal,
                              fontFamily: 'serif',
                            ),
                          ),
                          const Text(
                            'Panel de Usuario',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('passes')
                              .where('userId', isEqualTo: widget.userId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            var tokens = 0;
                            if (snapshot.hasData &&
                                snapshot.data!.docs.isNotEmpty) {
                              final bono = snapshot.data!.docs.where((d) {
                                final map = d.data()! as Map<String, dynamic>;
                                return map.safeBool('activo') &&
                                    map.safeInt('mes') == DateTime.now().month;
                              }).firstOrNull;
                              if (bono != null) {
                                tokens = (bono.data()! as Map<String, dynamic>)
                                    .safeInt('tokensRestantes');
                              }
                            }
                            return _buildSessionCard(tokens);
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(child: _buildQRCard()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GoldenGiftCard(userId: widget.userId),
                  const SizedBox(height: 35),
                  const Text(
                    'MIS RESERVAS RECIENTES',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _salufitTeal,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildBookingsList(),
                  const SizedBox(height: 30),
                  Center(
                    child: TextButton(
                      onPressed: _isDeleting ? null : _eliminarCuenta,
                      child: const Text(
                        'Eliminar mi cuenta definitivamente',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('CERRAR SESIÓN'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBookingsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('fechaReserva', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text(
            'No hay reservas activas.',
            style: TextStyle(color: Colors.grey),
          );
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final bData = doc.data()! as Map<String, dynamic>;
            final bookingId = doc.id;
            final classId = bData.safeString('groupClassId');
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('groupClasses')
                  .doc(classId)
                  .get(),
              builder: (context, cSnap) {
                if (!cSnap.hasData || !cSnap.data!.exists) {
                  return const SizedBox();
                }
                final cData = cSnap.data!.data()! as Map<String, dynamic>;
                final fecha = cData.safeDateTime('fechaHoraInicio');
                final nombreClase = cData.safeString('nombre');
                return _buildBookingItem(
                  bookingId: bookingId,
                  classId: classId,
                  fecha: fecha,
                  nombre: nombreClase,
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBookingItem({
    required String bookingId,
    required String classId,
    required DateTime fecha,
    required String nombre,
  }) {
    final gradient = _getCategoryGradient(nombre);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.fitness_center, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                Text(
                  DateFormat("EEEE d 'a las' HH:mm", 'es').format(fecha),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (_isCancelling) const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ) else IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white70),
                  onPressed: () => _cancelarReserva(
                    bookingId: bookingId,
                    classId: classId,
                    fecha: fecha,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(int count) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00E676), Color(0xFF00BFA5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -10,
            bottom: -10,
            child: Icon(Icons.bolt, size: 120, color: Colors.white24),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const Text(
                  'SESIONES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCard() {
    return InkWell(
      onTap: _mostrarQrGrande,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text(
              'ACCESO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00BFA5),
              ),
            ),
            QrImageView(data: widget.userId, size: 80),
            const Text(
              'Toca para ampliar',
              style: TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class GoldenGiftCard extends StatelessWidget {
  const GoldenGiftCard({required this.userId, super.key});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD600), Color(0xFFFFAB00)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(Icons.card_giftcard, size: 40, color: Colors.white),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                'TIENES UN REGALO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
