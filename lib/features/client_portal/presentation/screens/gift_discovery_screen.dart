import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/features/client_portal/providers/gift_hint_provider.dart';
import 'package:salufit_app/features/home/presentation/home_screen.dart';

class GiftDiscoveryScreen extends ConsumerStatefulWidget {
  const GiftDiscoveryScreen({required this.userId, super.key});
  final String userId;

  @override
  ConsumerState<GiftDiscoveryScreen> createState() =>
      _GiftDiscoveryScreenState();
}

class _GiftDiscoveryScreenState extends ConsumerState<GiftDiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    _analyzeAndNavigate();
  }

  Future<void> _analyzeAndNavigate() async {
    try {
      // 1. Simulación visual de análisis
      await Future<void>.delayed(const Duration(seconds: 2));

      final firestore = FirebaseFirestore.instance;

      // 2. Obtener historial reciente para personalizar el regalo
      final bookings = await firestore
          .collection('bookings')
          .where('userId', isEqualTo: widget.userId)
          .limit(10)
          .get();

      final history = bookings.docs
          .map((d) => d.data()['groupClassId']?.toString().toLowerCase() ?? '')
          .toList();

      // Lógica: Si no hay meditación en el historial, sugerimos meditación
      final suggestMeditation = !history.any((s) => s.contains('medita'));

      if (suggestMeditation) {
        // 3. Buscar la PRÓXIMA clase de meditación disponible para que la pantalla no esté vacía
        final nextMeditation = await firestore
            .collection('groupClasses')
            .where('nombre', isGreaterThanOrEqualTo: 'Meditación')
            .where('fechaHoraInicio', isGreaterThan: Timestamp.now())
            .orderBy('fechaHoraInicio')
            .limit(1)
            .get();

        DateTime? targetDate;
        if (nextMeditation.docs.isNotEmpty) {
          final data = nextMeditation.docs.first.data();
          targetDate = (data['fechaHoraInicio'] as Timestamp).toDate();
        }

        // 4. Activar el Hint y mover el calendario a esa fecha
        ref.read(giftHintProvider.notifier).activate(
              'Meditación',
              '¡Creemos que dedicar un día a meditar es el mejor regalo que puedes hacerte este mes!',
            );

        if (targetDate != null) {
          ref.read(bookingDateProvider.notifier).state = targetDate;
        }
      }

      // 5. Navegación coordinada
      if (mounted) {
        ref.read(homeTabProvider.notifier).state =
            1; // Cambiar a pestaña Clases
        Navigator.pop(context); // Cerrar pantalla de carga
      }
    } catch (e) {
      debugPrint('Error en GiftDiscovery: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo de imagen único (no repetido)
          Image.asset(
            'assets/login_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF009688),
            ),
          ),
          // Capa de oscurecimiento para legibilidad
          Container(
            color: Colors.black.withValues(alpha: 0.5),
          ),
          // Contenido central
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                SizedBox(height: 24),
                Text(
                  'ESTUDIANDO TUS ÚLTIMAS RESERVAS...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
