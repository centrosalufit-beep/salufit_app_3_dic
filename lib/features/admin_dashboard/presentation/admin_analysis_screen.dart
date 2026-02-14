import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

part 'admin_analysis_screen.g.dart';

// --- CLASE MODELO (Tipado Estricto) ---
@immutable
class AnalysisMetric {
  const AnalysisMetric({
    required this.label,
    required this.value,
    required this.isPositive,
  });

  /// Factory blindado contra nulos y tipos incorrectos
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

// --- PROVIDER (Riverpod Generator) ---
@riverpod
Future<List<AnalysisMetric>> adminAnalysis(Ref ref) async {
  // Changed AdminAnalysisRef to Ref
  // Tipado explícito para Future.delayed (Modo Estricto Dart)
  await Future<void>.delayed(const Duration(seconds: 1));

  // Simulación de respuesta API (Map crudo)
  // CORRECCIÓN LINTER: Eliminado 'Map<String, dynamic>' explícito, uso de var/final con inferencia
  final rawResponse = <String, dynamic>{
    'metrics': <Map<String, Object>>[
      <String, Object>{
        'label': 'Usuarios Activos',
        'value': 120.0,
        'isPositive': true,
      },
      <String, Object>{
        'label': 'Retención',
        'value': 85.5,
        'isPositive': false,
      },
    ],
  };

  // Sanitización y transformación en la capa lógica
  return rawResponse.safeList<AnalysisMetric>(
    'metrics',
    (dynamic item) {
      if (item is Map<String, dynamic>) {
        return AnalysisMetric.fromMap(item);
      }
      return const AnalysisMetric(label: 'Error', value: 0, isPositive: false);
    },
  );
}

class AdminAnalysisScreen extends ConsumerWidget {
  const AdminAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // CORRECCIÓN LINTER: Eliminado 'AsyncValue<...>' explícito
    final analysisState = ref.watch(adminAnalysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis del Sistema'),
        actions: const <Widget>[],
      ),
      body: analysisState.when(
        data: (List<AnalysisMetric> metrics) =>
            _AnalysisContent(metrics: metrics),
        error: (Object err, StackTrace stack) =>
            Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _AnalysisContent extends StatelessWidget {
  const _AnalysisContent({required this.metrics});

  final List<AnalysisMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: metrics.length,
      itemBuilder: (BuildContext context, int index) {
        // CORRECCIÓN LINTER: Eliminado 'AnalysisMetric' explícito
        final metric = metrics[index];

        return Card(
          child: ListTile(
            leading: Icon(
              metric.isPositive ? Icons.trending_up : Icons.trending_down,
              color: metric.isPositive ? Colors.green : Colors.red,
            ),
            title: Text(metric.label),
            trailing: Text(
              metric.value.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}
