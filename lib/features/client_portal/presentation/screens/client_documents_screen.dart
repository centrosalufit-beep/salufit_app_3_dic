import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/shared/widgets/salufit_header.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

// ═══════════════════════════════════════════════════════════════
// CONSTANTES DE MÉTRICAS
// ═══════════════════════════════════════════════════════════════

/// Polaridad: 'up' = subir es bueno, 'down' = bajar es bueno, 'neutral'.
const Map<String, List<Map<String, String>>> kMetricsTemplates = {
  'entrenamiento': [
    {'nombre': '1RM Press Banca', 'unidad': 'kg', 'polaridad': 'up'},
    {'nombre': '1RM Sentadilla', 'unidad': 'kg', 'polaridad': 'up'},
    {'nombre': '1RM Peso Muerto', 'unidad': 'kg', 'polaridad': 'up'},
    {'nombre': 'Peso Corporal', 'unidad': 'kg', 'polaridad': 'neutral'},
    {'nombre': 'Repeticiones máx', 'unidad': 'reps', 'polaridad': 'up'},
  ],
  'fisioterapia': [
    {'nombre': 'EVA Dolor', 'unidad': '/10', 'polaridad': 'down'},
    {'nombre': 'ROM Hombro', 'unidad': '°', 'polaridad': 'up'},
    {'nombre': 'ROM Rodilla', 'unidad': '°', 'polaridad': 'up'},
    {'nombre': 'Fuerza (Daniels)', 'unidad': '/5', 'polaridad': 'up'},
    {'nombre': 'Test Sit-and-Reach', 'unidad': 'cm', 'polaridad': 'up'},
  ],
  'nutricion': [
    {'nombre': 'Peso', 'unidad': 'kg', 'polaridad': 'neutral'},
    {'nombre': 'IMC', 'unidad': '', 'polaridad': 'down'},
    {'nombre': '% Grasa', 'unidad': '%', 'polaridad': 'down'},
    {'nombre': 'Perímetro Cintura', 'unidad': 'cm', 'polaridad': 'down'},
  ],
  'psicologia': [
    {'nombre': 'GAD-7 Ansiedad', 'unidad': '/21', 'polaridad': 'down'},
    {'nombre': 'PHQ-9 Depresión', 'unidad': '/27', 'polaridad': 'down'},
  ],
  'medicina': [
    {'nombre': 'Tensión Sistólica', 'unidad': 'mmHg', 'polaridad': 'down'},
    {'nombre': 'Tensión Diastólica', 'unidad': 'mmHg', 'polaridad': 'down'},
    {'nombre': 'FC Reposo', 'unidad': 'bpm', 'polaridad': 'down'},
  ],
  'odontologia': [
    {'nombre': 'Índice de Placa', 'unidad': '%', 'polaridad': 'down'},
    {'nombre': 'Profundidad Sondaje', 'unidad': 'mm', 'polaridad': 'down'},
  ],
};

// ═══════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL — MI EXPEDIENTE
// ═══════════════════════════════════════════════════════════════

class ClientDocumentsScreen extends StatefulWidget {
  const ClientDocumentsScreen({
    required this.userId,
    this.embedMode = false,
    super.key,
  });

  final String userId;
  final bool embedMode;

  @override
  State<ClientDocumentsScreen> createState() => _ClientDocumentsScreenState();
}

class _ClientDocumentsScreenState extends State<ClientDocumentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SalufitScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SalufitHeader(title: 'MI EXPEDIENTE'),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabs: const [
                Tab(
                  icon: Icon(Icons.show_chart, size: 18),
                  text: 'MÉTRICAS',
                ),
                Tab(
                  icon: Icon(Icons.verified, size: 18),
                  text: 'DOCUMENTOS',
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MetricsTab(userId: widget.userId),
                  _SignedConsentsTab(userId: widget.userId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 1: MÉTRICAS — MI EVOLUCIÓN
// ═══════════════════════════════════════════════════════════════

class _MetricsTab extends ConsumerWidget {
  const _MetricsTab({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref
          .watch(firebaseFirestoreProvider)
          .collection('patient_metrics')
          .where('userId', isEqualTo: userId)
          .limit(200)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];
        if (allDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text(
                  'Aún no tienes métricas registradas',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tu profesional las irá registrando en consulta',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          );
        }

        // Agrupar por nombre de métrica
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final doc in allDocs) {
          final data = doc.data()! as Map<String, dynamic>;
          final nombre = data.safeString('nombre', defaultValue: 'Métrica');
          grouped.putIfAbsent(nombre, () => []).add(data);
        }

        // Ordenar cada grupo por fecha
        for (final entries in grouped.values) {
          entries.sort((a, b) {
            final tsA = (a['fecha'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            final tsB = (b['fecha'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
            return tsA.compareTo(tsB);
          });
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: grouped.entries.map((entry) {
            return _MetricEvolutionCard(
              nombre: entry.key,
              entries: entry.value,
            );
          }).toList(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TARJETA DE EVOLUCIÓN POR MÉTRICA
// ═══════════════════════════════════════════════════════════════

class _MetricEvolutionCard extends StatelessWidget {
  const _MetricEvolutionCard({
    required this.nombre,
    required this.entries,
  });
  final String nombre;
  final List<Map<String, dynamic>> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final last = entries.last;
    final lastValue = (last['valor'] as num?)?.toDouble() ?? 0;
    final unidad = (last['unidad'] as String?) ?? '';
    final polaridad = (last['polaridad'] as String?) ?? 'neutral';
    final categoria = (last['categoria'] as String?) ?? '';
    final profesional = (last['profesionalNombre'] as String?) ?? '';
    final lastDate = (last['fecha'] as Timestamp?)?.toDate();
    final nota = (last['nota'] as String?) ?? '';

    // Delta vs primer registro
    String deltaText;
    Color deltaColor;
    if (entries.length > 1) {
      final firstValue = (entries.first['valor'] as num?)?.toDouble() ?? 0;
      final diff = lastValue - firstValue;
      final sign = diff > 0 ? '+' : '';
      deltaText = '$sign${diff.toStringAsFixed(1)}$unidad';

      if (polaridad == 'up') {
        deltaColor = diff >= 0 ? Colors.green : Colors.red;
      } else if (polaridad == 'down') {
        deltaColor = diff <= 0 ? Colors.green : Colors.red;
      } else {
        deltaColor = Colors.grey;
      }
    } else {
      deltaText = 'Primer registro';
      deltaColor = Colors.grey;
    }

    final catColor = _categoryColor(categoria);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: catColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      categoria.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: catColor,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    deltaText,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: deltaColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Nombre + valor
            Text(
              nombre,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      lastValue.toStringAsFixed(lastValue == lastValue.roundToDouble() ? 0 : 1),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: catColor,
                        height: 1,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unidad,
                    style: TextStyle(
                      fontSize: 14,
                      color: catColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Sparkline (mini gráfico con puntos)
            if (entries.length > 1) _buildSparkline(entries, catColor),
            if (entries.length > 1) const SizedBox(height: 10),
            // Info
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    profesional,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (lastDate != null)
                  Text(
                    DateFormat('dd/MM/yyyy').format(lastDate),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            if (nota.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '"$nota"',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSparkline(List<Map<String, dynamic>> data, Color color) {
    final values = data
        .map((e) => (e['valor'] as num?)?.toDouble() ?? 0)
        .toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = maxV - minV;

    return SizedBox(
      height: 40,
      child: CustomPaint(
        size: const Size(double.infinity, 40),
        painter: _SparklinePainter(
          values: values,
          minValue: range > 0 ? minV : minV - 1,
          maxValue: range > 0 ? maxV : maxV + 1,
          color: color,
        ),
      ),
    );
  }

  Color _categoryColor(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('entrena')) return const Color(0xFFD32F2F);
    if (c.contains('fisio')) return const Color(0xFF1976D2);
    if (c.contains('nutri')) return const Color(0xFF388E3C);
    if (c.contains('psico')) return const Color(0xFF7B1FA2);
    if (c.contains('medic')) return const Color(0xFF00796B);
    if (c.contains('odonto')) return const Color(0xFFE64A19);
    return const Color(0xFF009688);
  }
}

// ═══════════════════════════════════════════════════════════════
// SPARKLINE PAINTER
// ═══════════════════════════════════════════════════════════════

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.minValue,
    required this.maxValue,
    required this.color,
  });
  final List<double> values;
  final double minValue;
  final double maxValue;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final range = maxValue - minValue;
    final stepX = size.width / (values.length - 1);

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePath = Path();
    final fillPath = Path();

    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - ((values[i] - minValue) / range * size.height);

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath
          ..moveTo(x, size.height)
          ..lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }

    fillPath
      ..lineTo((values.length - 1) * stepX, size.height)
      ..close();

    canvas
      ..drawPath(fillPath, fillPaint)
      ..drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════
// TAB 2: CONSENTIMIENTOS FIRMADOS
// ═══════════════════════════════════════════════════════════════

class _SignedConsentsTab extends ConsumerWidget {
  const _SignedConsentsTab({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref
          .watch(firebaseFirestoreProvider)
          .collection('documents')
          .where('userId', isEqualTo: userId)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filtrar solo firmados en código
        final docs = (snapshot.data?.docs ?? []).where((d) {
          final data = d.data()! as Map<String, dynamic>;
          return data['firmado'] == true;
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified,
                  size: 50,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No hay consentimientos firmados',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data()! as Map<String, dynamic>;
            final titulo = data.safeString('titulo');
            final fechaFirma =
                (data['fechaFirma'] as Timestamp?)?.toDate();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified, color: Colors.green),
                ),
                title: Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: fechaFirma != null
                    ? Text(
                        'Firmado: ${DateFormat('dd/MM/yyyy HH:mm').format(fechaFirma)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                        ),
                      )
                    : null,
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          },
        );
      },
    );
  }
}
