// lib/shared/widgets/admin_banner.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminGenerationBanner extends ConsumerWidget {
  const AdminGenerationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    // 🛡️ REGLA DE NEGOCIO: Solo mostrar a partir del día 25
    if (now.day < 25) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('system_config')
          .doc('clases_generadas')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final nextMonthStr = '${now.year}-${(now.month % 12) + 1}';
        final data = snapshot.data!.data() as Map<String, dynamic>?;

        // Si ya se generó para el mes que viene, el banner desaparece para todos
        if (data?['ultimoMes'] == nextMonthStr) return const SizedBox.shrink();

        return Card(
          color: const Color(0xFF009688),
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  '📅 ¿GENERAR CLASES DEL PRÓXIMO MES?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "¿Quieres repetir el horario de la 'Semana Tipo' para el mes que viene?",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () => _ejecutarGeneracion(context),
                  child: const Text('SÍ, GENERAR AHORA'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _ejecutarGeneracion(BuildContext context) {
    // Aquí la App llama a la Cloud Function que creamos
  }
}
