import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/core/theme/app_colors.dart';

/// #6 — Banner con la última importación de Excel Clinni.
/// Si nunca se ha importado o tiene >2 días, advertencia en rojo.
final lastClinniImportProvider = StreamProvider<DateTime?>((ref) {
  final db = ref.watch(firebaseFirestoreProvider);
  return db
      .collection('audit_logs')
      .where('tipo', isEqualTo: 'CLINNI_IMPORT')
      .orderBy('timestamp', descending: true)
      .limit(1)
      .snapshots()
      .map((snap) {
    if (snap.docs.isEmpty) return null;
    final ts = snap.docs.first.data()['timestamp'] as Timestamp?;
    return ts?.toDate();
  });
});

/// #8 — KPIs básicos del bot: hoy enviados/confirmados/cancelados/escalados.
final todaysKpisProvider = StreamProvider<Map<String, int>>((ref) {
  final db = ref.watch(firebaseFirestoreProvider);
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);
  return db
      .collection('whatsapp_conversations')
      .where('fechaCreacion',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .snapshots()
      .map((snap) {
    var enviados = 0;
    var confirmados = 0;
    var cancelados = 0;
    var escalados = 0;
    for (final doc in snap.docs) {
      final d = doc.data();
      if (d['tipo'] == 'recordatorio') enviados++;
      final res = (d['resultado'] as String?) ?? '';
      if (res == 'cita_confirmada') confirmados++;
      if (res == 'cita_cancelada' ||
          res.startsWith('cancelar_')) {
        cancelados++;
      }
      if ((d['estado'] as String?) == 'escalada') escalados++;
    }
    return {
      'enviados': enviados,
      'confirmados': confirmados,
      'cancelados': cancelados,
      'escalados': escalados,
    };
  });
});

class BotStatusBanner extends ConsumerWidget {
  const BotStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importAsync = ref.watch(lastClinniImportProvider);
    final kpisAsync = ref.watch(todaysKpisProvider);
    final fmt = DateFormat('d MMM HH:mm', 'es');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        border: Border(bottom: BorderSide(color: Colors.indigo.shade100)),
      ),
      child: Row(
        children: [
          // #6 — última importación
          importAsync.when(
            data: (date) {
              if (date == null) {
                return _Pill(
                  icon: Icons.warning_amber_rounded,
                  text: '⚠️ Excel nunca importado',
                  color: Colors.red.shade700,
                );
              }
              final hours = DateTime.now().difference(date).inHours;
              final tooOld = hours > 48;
              return _Pill(
                icon: Icons.upload_file,
                text:
                    'Última importación: ${fmt.format(date)} (hace ${hours}h)',
                color: tooOld ? Colors.red.shade700 : Colors.green.shade700,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Spacer(),
          // #8 — KPIs hoy
          kpisAsync.when(
            data: (k) => Row(
              children: [
                _KpiBadge(
                    icon: Icons.send,
                    label: 'Enviados',
                    value: k['enviados'] ?? 0,
                    color: AppColors.primary),
                const SizedBox(width: 6),
                _KpiBadge(
                    icon: Icons.check,
                    label: 'Confirm.',
                    value: k['confirmados'] ?? 0,
                    color: Colors.green),
                const SizedBox(width: 6),
                _KpiBadge(
                    icon: Icons.cancel_outlined,
                    label: 'Canc.',
                    value: k['cancelados'] ?? 0,
                    color: Colors.orange),
                const SizedBox(width: 6),
                _KpiBadge(
                    icon: Icons.priority_high,
                    label: 'Escal.',
                    value: k['escalados'] ?? 0,
                    color: Colors.red),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _KpiBadge extends StatelessWidget {
  const _KpiBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text('$label $value',
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
