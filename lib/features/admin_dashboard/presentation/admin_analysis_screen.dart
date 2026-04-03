import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

part 'admin_analysis_screen.g.dart';

@immutable
class AnalysisMetric {
  const AnalysisMetric({required this.label, required this.value, required this.isPositive});
  factory AnalysisMetric.fromMap(Map<String, dynamic> map) {
    return AnalysisMetric(
      label: map.safeString('label', defaultValue: 'N/A'),
      value: map.safeDouble('value'),
      isPositive: map.safeBool('isPositive'),
    );
  }
  final String label;
  final double value;
  final bool isPositive;
}

@riverpod
class AdminAnalysis extends _$AdminAnalysis {
  @override
  FutureOr<List<AnalysisMetric>> build() async => _fetchRealMetrics();

  Future<List<AnalysisMetric>> _fetchRealMetrics() async {
    try {
      final now = DateTime.now();

      // Total de usuarios con app instalada
      final totalUsersQuery = await FirebaseFirestore.instance
          .collection('users_app')
          .count()
          .get();

      // Renovaciones este mes vs mes anterior
      final paymentsThisMonth = await FirebaseFirestore.instance
          .collection('monthly_payments')
          .where('mes', isEqualTo: now.month)
          .where('anio', isEqualTo: now.year)
          .count()
          .get();
      final prevMonth = DateTime(now.year, now.month - 1);
      final paymentsLastMonth = await FirebaseFirestore.instance
          .collection('monthly_payments')
          .where('mes', isEqualTo: prevMonth.month)
          .where('anio', isEqualTo: prevMonth.year)
          .count()
          .get();

      final renovados = paymentsThisMonth.count ?? 0;
      final prevRenovados = paymentsLastMonth.count ?? 0;
      final noRenovados = (prevRenovados - renovados).clamp(0, 9999);

      return [
        AnalysisMetric(
          label: 'App Instalada',
          value: (totalUsersQuery.count ?? 0).toDouble(),
          isPositive: true,
        ),
        AnalysisMetric(
          label: 'Renovados este mes',
          value: renovados.toDouble(),
          isPositive: true,
        ),
        AnalysisMetric(
          label: 'No renovados (vs mes anterior)',
          value: noRenovados.toDouble(),
          isPositive: false,
        ),
      ];
    } catch (e) {
      debugPrint('Error en Auditoría: $e');
      return [];
    }
  }

  Future<void> refreshMetrics() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchRealMetrics);
  }
}

class AdminAnalysisScreen extends ConsumerWidget {
  const AdminAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final analysisState = ref.watch(adminAnalysisProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Panel de Control (Windows)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importar renovaciones',
            onPressed: () => _showImportDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminAnalysisProvider.notifier).refreshMetrics(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (user != null) _ClockingStatusCard(userId: user.uid),
          const SizedBox(height: 24),
          Text('Métricas del Sistema', style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          analysisState.when(
            data: (metrics) => Column(
              children: metrics.map((m) => Card(
                color: Colors.white.withValues(alpha: 0.9),
                child: ListTile(
                  leading: Icon(m.isPositive ? Icons.trending_up : Icons.trending_down, color: m.isPositive ? Colors.green : Colors.red),
                  title: Text(m.label),
                  trailing: Text(m.value.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ),
              )).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => const Text('Error al cargar métricas', style: TextStyle(color: Colors.redAccent)),
          ),
          const SizedBox(height: 24),
          // Lista de no renovados
          const _NonRenewedList(),
        ],
      ),
    );
  }

  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.upload_file, color: Color(0xFF009688)),
            SizedBox(width: 8),
            Text('Importar Renovaciones'),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pega la lista de clientes que han pagado este mes '
                '(un nombre por línea). Se deduplicarán automáticamente.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Belén Maeso Carbayo\n'
                        'Carmen Lutzemkirchen\n'
                        'Ricardo Rivas\n'
                        '...',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check),
            label: const Text('IMPORTAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009688),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result != true || !context.mounted) return;

    final text = controller.text.trim();
    if (text.isEmpty) return;

    // Parsear nombres (deduplicar)
    final nombres = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toSet() // Deduplicar
        .toList();

    await _processImport(context, nombres, ref);
  }

  Future<void> _processImport(
    BuildContext context,
    List<String> nombres,
    WidgetRef ref,
  ) async {
    final messenger = ScaffoldMessenger.of(context)
      ..showSnackBar(
        SnackBar(
          content: Text('Procesando ${nombres.length} nombres...'),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(minutes: 1),
        ),
      );

    try {
      final now = DateTime.now();

      // Cargar pagos existentes este mes (para deduplicar)
      final existingPayments = await FirebaseFirestore.instance
          .collection('monthly_payments')
          .where('mes', isEqualTo: now.month)
          .where('anio', isEqualTo: now.year)
          .get();

      // Construir set de keywords existentes para deduplicar
      final existingKeys = <String>{};
      for (final doc in existingPayments.docs) {
        final data = doc.data();
        final kw = (data['keywords'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();
        if (kw != null && kw.isNotEmpty) {
          existingKeys.add(kw.join('|'));
        }
      }

      var added = 0;
      var duplicated = 0;
      final batch = FirebaseFirestore.instance.batch();

      for (final nombre in nombres) {
        final keywords = _toKeywords(nombre);
        if (keywords.isEmpty) continue;

        final keyStr = keywords.join('|');
        if (existingKeys.contains(keyStr)) {
          duplicated++;
          continue;
        }

        final docRef =
            FirebaseFirestore.instance.collection('monthly_payments').doc();
        batch.set(docRef, {
          'nombreCompleto': nombre.trim(),
          'keywords': keywords,
          'mes': now.month,
          'anio': now.year,
          'importadoEl': FieldValue.serverTimestamp(),
        });
        existingKeys.add(keyStr);
        added++;
      }

      await batch.commit();
      ref.read(adminAnalysisProvider.notifier).refreshMetrics();

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Importación: $added nuevos, $duplicated ya registrados',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    }
  }

  /// Convierte "Belén Maeso Carbayo " → ['belen', 'maeso', 'carbayo']
  static List<String> _toKeywords(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('ü', 'u')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }
}

// ═══════════════════════════════════════════════════════════════
// LISTA DE CLIENTES NO RENOVADOS
// ═══════════════════════════════════════════════════════════════

/// Compara mes anterior con mes actual: muestra quién pagó el mes pasado
/// pero NO aparece este mes.
class _NonRenewedList extends StatelessWidget {
  const _NonRenewedList();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1);

    return StreamBuilder<QuerySnapshot>(
      // Pagos del mes actual (reactivo)
      stream: FirebaseFirestore.instance
          .collection('monthly_payments')
          .where('mes', isEqualTo: now.month)
          .where('anio', isEqualTo: now.year)
          .snapshots(),
      builder: (context, currentSnap) {
        return FutureBuilder<QuerySnapshot>(
          // Pagos del mes anterior
          future: FirebaseFirestore.instance
              .collection('monthly_payments')
              .where('mes', isEqualTo: prevMonth.month)
              .where('anio', isEqualTo: prevMonth.year)
              .get(),
          builder: (context, prevSnap) {
            if (!prevSnap.hasData) return const SizedBox.shrink();

            // Keywords de este mes
            final currentKeys = <String>{};
            if (currentSnap.hasData) {
              for (final doc in currentSnap.data!.docs) {
                final data = doc.data()! as Map<String, dynamic>;
                final kw = (data['keywords'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .join('|');
                if (kw != null && kw.isNotEmpty) currentKeys.add(kw);
              }
            }

            // Personas del mes anterior que NO están este mes
            final nonRenewed = <String>[];
            for (final doc in prevSnap.data!.docs) {
              final data = doc.data()! as Map<String, dynamic>;
              final kw = (data['keywords'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .join('|');
              if (kw != null && !currentKeys.contains(kw)) {
                final nombre = data.safeString('nombreCompleto');
                if (nombre.isNotEmpty && !nonRenewed.contains(nombre)) {
                  nonRenewed.add(nombre);
                }
              }
            }

            if (nonRenewed.isEmpty && prevSnap.data!.docs.isEmpty) {
              return Card(
                color: Colors.grey.shade50,
                child: const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.grey),
                  title: Text('Importa las renovaciones del mes anterior para ver el churn'),
                ),
              );
            }

            if (nonRenewed.isEmpty) {
              return Card(
                color: Colors.green.shade50,
                child: const ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Todos los clientes del mes anterior han renovado'),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'NO RENOVADOS (${nonRenewed.length})',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (now.day <= 5)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'LLAMAR ANTES DEL 5',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ...nonRenewed.map(
                  (nombre) => Card(
                    color: Colors.white.withValues(alpha: 0.9),
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.person_off,
                        color: Colors.red,
                        size: 20,
                      ),
                      title: Text(
                        nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ClockingStatusCard extends StatelessWidget {
  const _ClockingStatusCard({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('timeClockRecords')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Card(child: ListTile(title: Text('Sin registros de jornada hoy')));
        }
        final doc = snapshot.data!.docs.first;
        final type = doc.get('type') as String;
        final timestamp = (doc.get('timestamp') as Timestamp?)?.toDate() ?? DateTime.now();
        final isClockedIn = type == 'IN';

        return Card(
          elevation: 4,
          color: isClockedIn ? Colors.teal.shade700 : Colors.white.withValues(alpha: 0.9),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(isClockedIn ? Icons.timer : Icons.timer_off, size: 40, color: isClockedIn ? Colors.white : Colors.grey),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isClockedIn ? 'JORNADA ACTIVA' : 'FUERA DE JORNADA', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: isClockedIn ? Colors.white : Colors.black87)),
                      Text('Último registro: ${DateFormat('HH:mm').format(timestamp)}', 
                        style: TextStyle(color: isClockedIn ? Colors.white70 : Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
                if (isClockedIn) const Text('EN CURSO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}
