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
      // Total de usuarios con app instalada (todos en users_app)
      final totalUsersQuery = await FirebaseFirestore.instance
          .collection('users_app')
          .count()
          .get();

      // Clientes sin bono activo este mes (no renovados)
      final now = DateTime.now();
      final clientesSnap = await FirebaseFirestore.instance
          .collection('users_app')
          .where('rol', isEqualTo: 'cliente')
          .get();
      final activePasses = await FirebaseFirestore.instance
          .collection('passes')
          .where('activo', isEqualTo: true)
          .where('mes', isEqualTo: now.month)
          .where('anio', isEqualTo: now.year)
          .get();
      final activeUserIds = <String>{};
      for (final doc in activePasses.docs) {
        final uid = (doc.data()['userId'] as String?) ?? '';
        if (uid.isNotEmpty) activeUserIds.add(uid);
      }
      final noRenovados = clientesSnap.docs
          .where((d) => !activeUserIds.contains(d.id))
          .length;

      return [
        AnalysisMetric(
          label: 'App Instalada',
          value: (totalUsersQuery.count ?? 0).toDouble(),
          isPositive: true,
        ),
        AnalysisMetric(
          label: 'Clientes no renovados',
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
        ],
      ),
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
