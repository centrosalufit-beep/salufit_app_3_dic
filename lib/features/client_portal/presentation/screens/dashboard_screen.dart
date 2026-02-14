import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/providers/places_provider.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';
import 'package:salufit_app/features/client_portal/presentation/providers/token_sync_provider.dart';
import 'package:salufit_app/features/home/providers/dashboard_providers.dart';
import 'package:salufit_app/shared/widgets/google_maps_card.dart';
import 'package:salufit_app/shared/widgets/pro_goal_card.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({required this.userId, super.key});
  final String userId;
  static const _salufitTeal = Color(0xFF009688);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokensAsync = ref.watch(userActiveTokensProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final nextClassAsync = ref.watch(nextClassProvider);
    final appointmentAsync = ref.watch(nextAppointmentProvider);

    return SalufitScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUnifiedHeader(userProfileAsync, tokensAsync),
              const SizedBox(height: 35),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProGoalCard(userId: userId),
                  const SizedBox(height: 16),
                  ref.watch(googlePlacesProvider).when(
                        data: (data) => GoogleMapsReviewCard(
                          rating: (data['rating'] as num?)?.toDouble() ?? 5,
                          reviewsCount:
                              (data['user_ratings_total'] as num?)?.toInt() ??
                                  523,
                        ),
                        loading: () => const GoogleMapsReviewCard(),
                        error: (_, __) => const GoogleMapsReviewCard(),
                      ),
                ],
              ),
              const SizedBox(height: 35),
              const Text(
                'TU ACTIVIDAD PRÓXIMA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 15),
              nextClassAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _buildEmptyCard(
                  'TU PRÓXIMA CLASE',
                  'Sin datos',
                  Icons.error,
                ),
                data: (claseData) {
                  if (claseData == null) {
                    return _buildEmptyCard(
                      'TU PRÓXIMA CLASE',
                      'Sin reservas próximas',
                      Icons.fitness_center,
                    );
                  }
                  final fecha = claseData['fecha'] as DateTime;
                  final nombreClase = claseData['nombre'] as String;
                  var diaStr = DateFormat('EEEE d', 'es').format(fecha);
                  diaStr = '${diaStr[0].toUpperCase()}${diaStr.substring(1)}';
                  final hora = DateFormat('HH:mm').format(fecha);
                  final visual = _getClassVisuals(nombreClase);
                  return _buildDiscoverCard(
                    title: 'TU PRÓXIMA CLASE',
                    mainText: nombreClase,
                    subText: '$diaStr a las $hora',
                    colors: (visual['colors'] as List).cast<Color>(),
                    icon: visual['icon'] as IconData,
                  );
                },
              ),
              const SizedBox(height: 25),
              appointmentAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _buildEmptyCard(
                  'CITA MÉDICA',
                  'Error de carga',
                  Icons.error,
                ),
                data: (citaDoc) {
                  if (citaDoc == null || !citaDoc.exists) {
                    return _buildEmptyCard(
                      'CITA MÉDICA',
                      'Sin citas programadas',
                      Icons.medical_services_outlined,
                    );
                  }
                  final data = citaDoc.data()! as Map<String, dynamic>;
                  final fechaRaw = data['fechaHoraInicio'];
                  final fecha = (fechaRaw is Timestamp)
                      ? fechaRaw.toDate()
                      : DateTime.now();
                  var diaStr = DateFormat('EEEE d', 'es').format(fecha);
                  diaStr = '${diaStr[0].toUpperCase()}${diaStr.substring(1)}';
                  final hora = DateFormat('HH:mm').format(fecha);
                  final profesional = data.safeString(
                    'profesionalId',
                    defaultValue: 'Equipo Salufit',
                  );
                  return _buildDiscoverCard(
                    title: 'PRÓXIMA CITA MÉDICA',
                    mainText: 'FISIOTERAPIA',
                    subText: '$diaStr a las $hora\nCon: $profesional',
                    colors: const [_salufitTeal, Color(0xFF4DB6AC)],
                    icon: Icons.medical_services_outlined,
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

  Widget _buildUnifiedHeader(
    AsyncValue<DocumentSnapshot<Map<String, dynamic>>> profile,
    AsyncValue<int> tokens,
  ) {
    return profile.when(
      data: (doc) {
        final name = doc.data().safeString('nombre', defaultValue: 'Usuario');
        final saldo = tokens.value ?? 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡HOLA, ${name.toUpperCase()}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _salufitTeal,
                    fontFamily: 'serif',
                  ),
                ),
                const Text(
                  'tu salud en manos profesionales',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _salufitTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    '$saldo',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _salufitTeal,
                    ),
                  ),
                  const Text('SESIONES', style: TextStyle(fontSize: 8)),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 60),
      error: (_, __) => const Text('Bienvenido'),
    );
  }

  Map<String, dynamic> _getClassVisuals(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('entrenamiento')) {
      return {
        'colors': const [Color(0xFFD32F2F), Color(0xFFE57373)],
        'icon': Icons.fitness_center,
      };
    }
    if (n.contains('medita')) {
      return {
        'colors': const [Color(0xFF7B1FA2), Color(0xFFBA68C8)],
        'icon': Icons.self_improvement,
      };
    }
    return {
      'colors': const [Color(0xFF1976D2), Color(0xFF64B5F6)],
      'icon': Icons.sports_gymnastics,
    };
  }

  Widget _buildDiscoverCard({
    required String title,
    required String mainText,
    required String subText,
    required List<Color> colors,
    required IconData icon,
  }) {
    return Container(
      height: 145,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(
              icon,
              size: 130,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  mainText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String title, String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade300, size: 30),
              const SizedBox(width: 10),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
