import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

class ProGoalCard extends StatelessWidget {
  const ProGoalCard({
    required this.userId,
    super.key,
  });

  final String userId;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // 1. Rango de la semana actual (Lunes 00:00 a Domingo 23:59)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfRange =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfRange = startOfRange.add(const Duration(days: 7));

    return StreamBuilder<QuerySnapshot>(
      // 2. Obtener el pase activo para determinar la cuota semanal
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
        final totalMensual = passData.safeInt('tokensTotales', defaultValue: 8);

        // 3. Meta semanal (Total / 4 semanas)
        final metaSemanal = (totalMensual / 4).ceil();

        return StreamBuilder<QuerySnapshot>(
          // 4. Consultar actividad real de la semana
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: userId)
              .where(
                'fechaReserva',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfRange),
              )
              .where('fechaReserva', isLessThan: Timestamp.fromDate(endOfRange))
              .snapshots(),
          builder: (context, bookingSnapshot) {
            final consumidasEstaSemana =
                bookingSnapshot.hasData ? bookingSnapshot.data!.docs.length : 0;
            final restantesEstaSemana =
                (metaSemanal - consumidasEstaSemana).clamp(0, metaSemanal);

            // Progreso relativo al objetivo de 7 días
            final progreso =
                (consumidasEstaSemana / metaSemanal).clamp(0.0, 1.0);

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF009688),
                    Color(0xFF4DB6AC),
                  ],
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
                  // Indicador Visual Circular
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
                        restantesEstaSemana == 0 ? Icons.check : Icons.bolt,
                        color: Colors.white,
                        size: 30,
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Textos de Objetivo
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
                          restantesEstaSemana > 0
                              ? '$restantesEstaSemana ${restantesEstaSemana == 1 ? "CLASE" : "CLASES"} RESTANTES'
                              : 'OBJETIVO CUMPLIDO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22, // Tamaño grande solicitado
                            fontWeight: FontWeight.w900, // Grosor extra
                            fontFamily: 'serif',
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restantesEstaSemana > 0
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
          },
        );
      },
    );
  }
}
