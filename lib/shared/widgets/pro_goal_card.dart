import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

class ProGoalCard extends StatelessWidget {
  const ProGoalCard({
    required this.userId,
    this.onTrialTap,
    super.key,
  });

  final String userId;

  /// Callback cuando el usuario pulse la tarjeta de prueba gratuita.
  /// Si es null, se busca el HomeTab provider desde el ancestor.
  final VoidCallback? onTrialTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfRange =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfRange = startOfRange.add(const Duration(days: 7));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('passes')
          .where('userId', isEqualTo: userId)
          .where('activo', isEqualTo: true)
          .where('mes', isEqualTo: now.month)
          .where('anio', isEqualTo: now.year)
          .limit(1)
          .snapshots(),
      builder: (context, passSnapshot) {
        if (!passSnapshot.hasData || passSnapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final passData =
            passSnapshot.data!.docs.first.data() as Map<String, dynamic>?;
        final totalMensual =
            passData.safeInt('tokensTotales', defaultValue: 8);
        final tokensRestantes =
            passData.safeInt('tokensRestantes');

        // === BONO DE PRUEBA (1 token) ===
        if (totalMensual == 1) {
          return _TrialPromoCard(
            hasUsedTrial: tokensRestantes == 0,
            onTap: onTrialTap,
          );
        }

        // === BONO NORMAL: objetivo semanal ===
        final metaSemanal = (totalMensual / 4).ceil();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: userId)
              .where(
                'fechaReserva',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfRange),
              )
              .where(
                'fechaReserva',
                isLessThan: Timestamp.fromDate(endOfRange),
              )
              .snapshots(),
          builder: (context, bookingSnapshot) {
            final consumidas = bookingSnapshot.hasData
                ? bookingSnapshot.data!.docs.length
                : 0;
            final restantes =
                (metaSemanal - consumidas).clamp(0, metaSemanal);
            final progreso =
                (consumidas / metaSemanal).clamp(0.0, 1.0);

            return _WeeklyGoalCard(
              restantes: restantes,
              progreso: progreso,
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TARJETA OBJETIVO SEMANAL (bonos normales)
// ═══════════════════════════════════════════════════════════════

class _WeeklyGoalCard extends StatelessWidget {
  const _WeeklyGoalCard({
    required this.restantes,
    required this.progreso,
  });
  final int restantes;
  final double progreso;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF009688), Color(0xFF4DB6AC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF009688).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 65,
                height: 65,
                child: CircularProgressIndicator(
                  value: progreso,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                  strokeWidth: 8,
                ),
              ),
              Icon(
                restantes == 0 ? Icons.check : Icons.bolt,
                color: Colors.white,
                size: 30,
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OBJETIVO SEMANAL',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  restantes > 0
                      ? '$restantes ${restantes == 1 ? "CLASE" : "CLASES"} RESTANTES'
                      : 'OBJETIVO CUMPLIDO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'serif',
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  restantes > 0
                      ? 'Ánimo, ¡a por tu meta!'
                      : '¡Buen trabajo esta semana!',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
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

// ═══════════════════════════════════════════════════════════════
// TARJETA PROMOCIONAL — BONO DE PRUEBA (1 token)
// ═══════════════════════════════════════════════════════════════

class _TrialPromoCard extends StatefulWidget {
  const _TrialPromoCard({
    required this.hasUsedTrial,
    this.onTap,
  });
  final bool hasUsedTrial;
  final VoidCallback? onTap;

  @override
  State<_TrialPromoCard> createState() => _TrialPromoCardState();
}

class _TrialPromoCardState extends State<_TrialPromoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si ya usó su clase gratuita → CTA para contratar bono
    if (widget.hasUsedTrial) return _buildUsedTrialCard();

    // Token disponible → Promoción irrechazable
    return _buildAvailableTrialCard();
  }

  Widget _buildAvailableTrialCard() {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF6F00), // Amber oscuro
                  Color(0xFFFFCA28), // Dorado
                  Color(0xFFFF8F00), // Amber medio
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8F00).withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Icono de fondo decorativo
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    Icons.card_giftcard,
                    size: 100,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                // Shimmer overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment(
                            -1 + 2 * _shimmerController.value,
                            0,
                          ),
                          end: Alignment(
                            -1 + 2 * _shimmerController.value + 0.6,
                            0,
                          ),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: Container(color: Colors.white),
                    ),
                  ),
                ),
                // Contenido
                Row(
                  children: [
                    // Icono principal
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 18),
                    // Textos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'EXCLUSIVO PARA TI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'TU PRIMERA CLASE\nES GRATIS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.touch_app,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Toca para reservar ahora',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Flecha
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsedTrialCard() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A1B9A).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                Icons.star,
                size: 90,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'YA PROBASTE TU CLASE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '¿TE GUSTÓ?\nHAZTE MIEMBRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Consulta nuestros bonos mensuales',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
