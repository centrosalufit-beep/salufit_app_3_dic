import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/providers/places_provider.dart';
import 'package:salufit_app/features/auth/domain/user_model.dart';
import 'package:salufit_app/features/auth/providers/user_profile_provider.dart';
import 'package:salufit_app/features/client_portal/presentation/providers/token_sync_provider.dart';
import 'package:salufit_app/features/home/presentation/home_providers.dart';
import 'package:salufit_app/features/home/providers/dashboard_providers.dart';
import 'package:salufit_app/shared/widgets/google_maps_card.dart';
import 'package:salufit_app/shared/widgets/pro_goal_card.dart';
import 'package:salufit_app/shared/widgets/salufit_header.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

class ClientDashboardScreen extends ConsumerWidget {
  const ClientDashboardScreen({required this.userId, super.key});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokensAsync = ref.watch(userActiveTokensProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final nextClassAsync = ref.watch(nextClassProvider);

    return SalufitScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDashboardHeader(userProfileAsync, tokensAsync),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ProGoalCard(
                      userId: userId,
                      onTrialTap: () =>
                          ref.read(homeTabProvider.notifier).setTab(1),
                    ),
                    const SizedBox(height: 16),
                    ref.watch(googlePlacesProvider).when(
                      data: (data) => GoogleMapsReviewCard(
                        rating: (data['rating'] as num?)?.toDouble() ?? 5,
                        reviewsCount: (data['user_ratings_total'] as num?)?.toInt() ?? 523,
                      ),
                      loading: () => const GoogleMapsReviewCard(),
                      error: (_, __) => const GoogleMapsReviewCard(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('TU ACTIVIDAD PRÓXIMA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: nextClassAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _buildEmptyCard('TU PRÓXIMA CLASE', 'Sin datos', Icons.error),
                  data: (claseData) {
                    if (claseData == null) return _buildEmptyCard('TU PRÓXIMA CLASE', 'Sin reservas', Icons.fitness_center);
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
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardHeader(AsyncValue<UserModel?> profile, AsyncValue<int> tokens) {
    return profile.when(
      data: (user) {
        final name = user?.nombre ?? 'Usuario';
        final saldo = tokens.value ?? 0;
        final isActive = saldo > 0;
        final colors = isActive
            ? [Colors.lightGreenAccent.shade700, Colors.tealAccent.shade700]
            : [Colors.deepOrangeAccent, Colors.orange.shade800];
        return SalufitHeader(
          title: '!HOLA, ${name.toUpperCase()}!',
          subtitle: 'tu salud en manos profesionales',
          trailing: Container(
            width: 80,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: colors[0].withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Stack(
              children: [
                Positioned(right: -12, bottom: -12, child: Icon(Icons.bolt, size: 60, color: Colors.white.withValues(alpha: 0.15))),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(6)),
                        child: Text(isActive ? 'ACTIVO' : 'AGOTADO', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 7)),
                      ),
                      const SizedBox(height: 2),
                      Text('$saldo', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                      const Text('TOKENS', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 80),
      error: (_, __) => const SalufitHeader(title: 'BIENVENIDO'),
    );
  }

  Map<String, dynamic> _getClassVisuals(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('entrenamiento')) return {'colors': const [Color(0xFFC62828), Color(0xFFFF5252)], 'icon': Icons.fitness_center};
    if (n.contains('meditación') || n.contains('meditacion')) return {'colors': const [Color(0xFF4A148C), Color(0xFFAB47BC)], 'icon': Icons.self_improvement};
    if (n.contains('tribu') || n.contains('activa')) return {'colors': const [Color(0xFFE65100), Color(0xFFFFB74D)], 'icon': Icons.directions_walk};
    if (n.contains('terapéutico') || n.contains('terapeutico')) return {'colors': const [Color(0xFF0D47A1), Color(0xFF42A5F5)], 'icon': Icons.self_improvement};
    if (n.contains('kids') || n.contains('explora')) return {'colors': const [Color(0xFF00897B), Color(0xFF4DB6AC)], 'icon': Icons.escalator_warning};
    return {'colors': const [Color(0xFF1976D2), Color(0xFF64B5F6)], 'icon': Icons.sports_gymnastics};
  }

  Widget _buildDiscoverCard({required String title, required String mainText, required String subText, required List<Color> colors, required IconData icon}) {
    return Container(
      height: 145,
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20)),
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
                Text(mainText, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Row(children: [const Icon(Icons.calendar_today, color: Colors.white, size: 14), const SizedBox(width: 8), Expanded(child: Text(subText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, height: 1.3)))]),
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
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 10),
          Row(children: [Icon(icon, color: Colors.grey.shade300, size: 30), const SizedBox(width: 10), Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey))]),
        ],
      ),
    );
  }
}
