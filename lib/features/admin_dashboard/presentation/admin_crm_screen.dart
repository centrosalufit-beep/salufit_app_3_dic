import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

// ═══════════════════════════════════════════════════════════════
// CONSTANTES
// ═══════════════════════════════════════════════════════════════

const int _kMetaGrupalMensual = 4;

const List<String> _kCanales = [
  'web',
  'b2b',
  'instagram',
  'recomendacion',
  'derivacion',
  'telefono',
  'evento',
  'gmaps',
];

const Map<String, ({IconData icon, String label})> _kCanalInfo = {
  'web': (icon: Icons.language, label: 'Web'),
  'b2b': (icon: Icons.handshake, label: 'B2B'),
  'instagram': (icon: Icons.camera_alt, label: 'Instagram'),
  'recomendacion': (icon: Icons.record_voice_over, label: 'Recomendación'),
  'derivacion': (icon: Icons.swap_horiz, label: 'Derivación'),
  'telefono': (icon: Icons.phone, label: 'Teléfono'),
  'evento': (icon: Icons.event, label: 'Evento'),
  'gmaps': (icon: Icons.place, label: 'Google Maps'),
};

// ═══════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL CRM
// ═══════════════════════════════════════════════════════════════

class AdminCrmScreen extends StatefulWidget {
  const AdminCrmScreen({
    required this.userId,
    required this.userRole,
    super.key,
  });
  final String userId;
  final String userRole;

  @override
  State<AdminCrmScreen> createState() => _AdminCrmScreenState();
}

class _AdminCrmScreenState extends State<AdminCrmScreen> {
  late DateTime _selectedMonth;
  bool get _isAdmin =>
      widget.userRole == 'admin' || widget.userRole == 'administrador';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
  }

  // ── Queries ───────────────────────────────────────────────

  Stream<QuerySnapshot> _entriesStream(int mes, int anio) {
    var query = FirebaseFirestore.instance
        .collection('crm_entries')
        .where('mes', isEqualTo: mes)
        .where('anio', isEqualTo: anio);
    if (!_isAdmin) {
      query = query.where('profesionalId', isEqualTo: widget.userId);
    }
    return query.snapshots();
  }

  Future<List<QueryDocumentSnapshot>> _entriesForMonth(
    int mes,
    int anio,
  ) async {
    var query = FirebaseFirestore.instance
        .collection('crm_entries')
        .where('mes', isEqualTo: mes)
        .where('anio', isEqualTo: anio);
    if (!_isAdmin) {
      query = query.where('profesionalId', isEqualTo: widget.userId);
    }
    final snap = await query.get();
    return snap.docs;
  }

  // ── Profesionales ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _loadProfesionales() async {
    final snap = await FirebaseFirestore.instance
        .collection('users_app')
        .where(
          'rol',
          whereIn: const ['admin', 'administrador', 'profesional'],
        )
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return {
        'id': d.id,
        'nombre': data.safeString('nombreCompleto').isNotEmpty
            ? data.safeString('nombreCompleto')
            : data.safeString('nombre'),
      };
    }).toList();
  }

  // ── Registrar grupal ──────────────────────────────────────

  Future<void> _registrarGrupal() async {
    final now = DateTime.now();

    // Validar: máximo 1 por día (query simple mes+anio, filtro en código)
    final existing = await FirebaseFirestore.instance
        .collection('crm_entries')
        .where('mes', isEqualTo: now.month)
        .where('anio', isEqualTo: now.year)
        .get();

    final hoy = DateTime(now.year, now.month, now.day);
    final yaRegistroHoy = existing.docs.any((doc) {
      final data = doc.data();
      if (data.safeString('profesionalId') != widget.userId) return false;
      if (data.safeString('tipo') != 'grupal') return false;
      final ts = (data['fechaCreacion'] as Timestamp?)?.toDate();
      if (ts == null) return false;
      return ts.year == hoy.year && ts.month == hoy.month && ts.day == hoy.day;
    });

    if (yaRegistroHoy) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya registraste tu hora grupal hoy'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Resolver nombre
    final userName = await _resolveUserName(widget.userId);

    await FirebaseFirestore.instance.collection('crm_entries').add({
      'tipo': 'grupal',
      'profesionalId': widget.userId,
      'profesionalNombre': userName,
      'mes': now.month,
      'anio': now.year,
      'creadoPor': widget.userId,
      'fechaCreacion': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hora grupal registrada'),
          backgroundColor: Color(0xFF009688),
        ),
      );
    }
  }

  Future<String> _resolveUserName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users_app')
          .doc(uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final full = data.safeString('nombreCompleto');
        if (full.isNotEmpty) return full;
        final name = data.safeString('nombre');
        if (name.isNotEmpty) return name;
      }
    } catch (_) {}
    return uid;
  }

  // ── Diálogo: Añadir Reseña ────────────────────────────────

  Future<void> _addResena() async {
    final profesionales = await _loadProfesionales();
    if (!mounted) return;

    String? selectedProId;
    String? selectedProNombre;
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Nueva Reseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Profesional',
                  border: OutlineInputBorder(),
                ),
                items: profesionales
                    .map(
                      (p) => DropdownMenuItem(
                        value: p['id'] as String,
                        child: Text(p['nombre'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  selectedProId = v;
                  selectedProNombre = profesionales
                      .firstWhere((p) => p['id'] == v)['nombre'] as String;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  hintText: 'Ej: Google 5★, Doctoralia...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: selectedProId == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                foregroundColor: Colors.white,
              ),
              child: const Text('REGISTRAR'),
            ),
          ],
        ),
      ),
    );

    if (result != true || selectedProId == null) return;
    final now = DateTime.now();
    await FirebaseFirestore.instance.collection('crm_entries').add({
      'tipo': 'resena',
      'profesionalId': selectedProId,
      'profesionalNombre': selectedProNombre,
      'descripcion': descController.text.trim(),
      'mes': now.month,
      'anio': now.year,
      'creadoPor': widget.userId,
      'fechaCreacion': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reseña registrada'),
          backgroundColor: Color(0xFF009688),
        ),
      );
    }
  }

  // ── Diálogo: Añadir Referencia (modelo Excel completo) ──────

  Future<void> _addReferencia() async {
    final profesionales = await _loadProfesionales();
    if (!mounted) return;

    String? emiteId;
    String? emiteNombre;
    String? recibeId;
    String? recibeNombre;
    String? selectedCanal;
    var estado = 'citado';
    final numHistoriaCtrl = TextEditingController();
    final importeCtrl = TextEditingController();
    final anotacionesCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.link, color: Color(0xFF009688)),
              SizedBox(width: 8),
              Text('Nueva Referencia'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila 1: Nº Historia + Importe
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: numHistoriaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nº Historia',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge, size: 18),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 130,
                        child: TextField(
                          controller: importeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Importe €',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.euro, size: 18),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Canal de captación
                  const Text(
                    'Origen:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _kCanales.map((canal) {
                      final info = _kCanalInfo[canal]!;
                      final isSelected = selectedCanal == canal;
                      return ChoiceChip(
                        avatar: Icon(
                          info.icon,
                          size: 16,
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                        label: Text(info.label),
                        selected: isSelected,
                        selectedColor: const Color(0xFF009688),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12,
                        ),
                        onSelected: (_) =>
                            setDs(() => selectedCanal = canal),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Emite + Recibe
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Emite',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: profesionales
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p['id'] as String,
                                  child: Text(
                                    p['nombre'] as String,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setDs(() {
                            emiteId = v;
                            emiteNombre = profesionales
                                .firstWhere(
                                  (p) => p['id'] == v,
                                )['nombre'] as String;
                          }),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, color: Colors.grey),
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Recibe',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: profesionales
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p['id'] as String,
                                  child: Text(
                                    p['nombre'] as String,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setDs(() {
                            recibeId = v;
                            recibeNombre = profesionales
                                .firstWhere(
                                  (p) => p['id'] == v,
                                )['nombre'] as String;
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Estado
                  Row(
                    children: [
                      const Text(
                        'Estado:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Citado'),
                        selected: estado == 'citado',
                        selectedColor: Colors.green.shade100,
                        onSelected: (_) =>
                            setDs(() => estado = 'citado'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Pendiente'),
                        selected: estado == 'pendiente',
                        selectedColor: Colors.orange.shade100,
                        onSelected: (_) =>
                            setDs(() => estado = 'pendiente'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Sin éxito'),
                        selected: estado == 'sin_exito',
                        selectedColor: Colors.red.shade100,
                        onSelected: (_) =>
                            setDs(() => estado = 'sin_exito'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Anotaciones
                  TextField(
                    controller: anotacionesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Anotaciones (opcional)',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: Amiga de Belén, viene de la otra clínica...',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed:
                  (emiteId != null && recibeId != null && selectedCanal != null)
                      ? () => Navigator.pop(ctx, true)
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                foregroundColor: Colors.white,
              ),
              child: const Text('REGISTRAR'),
            ),
          ],
        ),
      ),
    );

    if (result != true ||
        emiteId == null ||
        recibeId == null ||
        selectedCanal == null) {
      return;
    }

    final now = DateTime.now();
    final importe = double.tryParse(
      importeCtrl.text.replaceAll(',', '.').trim(),
    );

    await FirebaseFirestore.instance.collection('crm_entries').add({
      'tipo': 'referencia',
      // Quién emite (genera la referencia)
      'profesionalId': emiteId,
      'profesionalNombre': emiteNombre,
      // Quién recibe (al paciente)
      'recibeId': recibeId,
      'recibeNombre': recibeNombre,
      // Datos del paciente/referencia
      'numHistoria': numHistoriaCtrl.text.trim(),
      'canal': selectedCanal,
      'estado': estado,
      if (importe != null) 'importe': importe,
      'anotaciones': anotacionesCtrl.text.trim(),
      // Meta
      'mes': now.month,
      'anio': now.year,
      'creadoPor': widget.userId,
      'fechaCreacion': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referencia registrada'),
          backgroundColor: Color(0xFF009688),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final mes = _selectedMonth.month;
    final anio = _selectedMonth.year;
    final mesAnterior = DateTime(anio, mes - 1);
    final mesesNombres = [
      '',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.leaderboard, size: 22),
            const SizedBox(width: 10),
            Text(_isAdmin ? 'Rendimiento Equipo' : 'Mi Rendimiento'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            '${mesesNombres[mes]} $anio',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _selectedMonth.month == DateTime.now().month &&
                    _selectedMonth.year == DateTime.now().year
                ? null
                : () => _changeMonth(1),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _entriesStream(mes, anio),
        builder: (context, currentSnap) {
          if (!currentSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentEntries = currentSnap.data!.docs;

          return FutureBuilder<List<QueryDocumentSnapshot>>(
            future: _entriesForMonth(
              mesAnterior.month,
              mesAnterior.year,
            ),
            builder: (context, prevSnap) {
              final prevEntries = prevSnap.data ?? [];

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Pools por profesional
                  ..._buildProfessionalPools(
                    currentEntries,
                    prevEntries,
                  ),
                  const SizedBox(height: 20),

                  // Totales con desglose (solo admin)
                  if (_isAdmin)
                    _buildTotalsCard(currentEntries, prevEntries),
                  if (_isAdmin) const SizedBox(height: 16),

                  // Canales de captación (solo admin)
                  if (_isAdmin) _buildChannelsCard(currentEntries),
                  if (_isAdmin) const SizedBox(height: 16),

                  // Derivaciones cruzadas (solo admin)
                  if (_isAdmin) _buildCrossDerivationsCard(currentEntries),
                  if (_isAdmin) const SizedBox(height: 16),

                  // Botón grupal (profesional o admin)
                  _buildGrupalButton(currentEntries),
                  const SizedBox(height: 16),

                  // Botones admin
                  if (_isAdmin) _buildAdminButtons(),
                  if (_isAdmin) const SizedBox(height: 20),

                  // Gráfico trimestral
                  _buildTrimestralChart(),
                  const SizedBox(height: 40),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════════════════════

  List<Widget> _buildProfessionalPools(
    List<QueryDocumentSnapshot> current,
    List<QueryDocumentSnapshot> prev,
  ) {
    // Agrupar por profesional
    final proIds = <String>{};
    for (final doc in current) {
      final data = doc.data()! as Map<String, dynamic>;
      proIds.add(data.safeString('profesionalId'));
    }
    for (final doc in prev) {
      final data = doc.data()! as Map<String, dynamic>;
      proIds.add(data.safeString('profesionalId'));
    }

    if (!_isAdmin) proIds.retainAll({widget.userId});

    return proIds.map((proId) {
      final curFiltered = current.where((d) {
        final data = d.data()! as Map<String, dynamic>;
        return data.safeString('profesionalId') == proId;
      }).toList();
      final prevFiltered = prev.where((d) {
        final data = d.data()! as Map<String, dynamic>;
        return data.safeString('profesionalId') == proId;
      }).toList();

      final nombre = curFiltered.isNotEmpty
          ? (curFiltered.first.data()! as Map<String, dynamic>)
              .safeString('profesionalNombre')
          : prevFiltered.isNotEmpty
              ? (prevFiltered.first.data()! as Map<String, dynamic>)
                  .safeString('profesionalNombre')
              : proId;

      final resenas = curFiltered
          .where(
            (d) => (d.data()! as Map<String, dynamic>).safeString('tipo') == 'resena',
          )
          .length;
      final refs = curFiltered
          .where(
            (d) => (d.data()! as Map<String, dynamic>).safeString('tipo') == 'referencia',
          )
          .length;
      final grupales = curFiltered
          .where(
            (d) => (d.data()! as Map<String, dynamic>).safeString('tipo') == 'grupal',
          )
          .length;

      final prevResenas = prevFiltered
          .where(
            (d) => (d.data()! as Map<String, dynamic>).safeString('tipo') == 'resena',
          )
          .length;
      final prevRefs = prevFiltered
          .where(
            (d) => (d.data()! as Map<String, dynamic>).safeString('tipo') == 'referencia',
          )
          .length;
      final prevGrupales = prevFiltered
          .where(
            (d) => (d.data()! as Map<String, dynamic>).safeString('tipo') == 'grupal',
          )
          .length;

      return _ProfessionalPoolCard(
        nombre: nombre,
        resenas: resenas,
        referencias: refs,
        grupales: grupales,
        prevResenas: prevResenas,
        prevReferencias: prevRefs,
        prevGrupales: prevGrupales,
      );
    }).toList();
  }

  /// Desglose por profesional para un tipo dado.
  Map<String, int> _breakdownByPro(
    List<QueryDocumentSnapshot> entries,
    String tipo,
  ) {
    final map = <String, int>{};
    for (final doc in entries) {
      final data = doc.data()! as Map<String, dynamic>;
      if (data.safeString('tipo') != tipo) continue;
      final nombre = data.safeString('profesionalNombre', defaultValue: '?');
      final shortName = nombre.split(' ').first;
      map[shortName] = (map[shortName] ?? 0) + 1;
    }
    return map;
  }

  Widget _buildTotalsCard(
    List<QueryDocumentSnapshot> current,
    List<QueryDocumentSnapshot> prev,
  ) {
    int count(List<QueryDocumentSnapshot> list, String tipo) =>
        list.where((d) => (d.data()! as Map<String, dynamic>).safeString('tipo') == tipo).length;

    final r = count(current, 'resena');
    final ref = count(current, 'referencia');
    final g = count(current, 'grupal');

    final resNow = _breakdownByPro(current, 'resena');
    final refNow = _breakdownByPro(current, 'referencia');
    final grpNow = _breakdownByPro(current, 'grupal');
    final resPrev = _breakdownByPro(prev, 'resena');
    final refPrev = _breakdownByPro(prev, 'referencia');
    final grpPrev = _breakdownByPro(prev, 'grupal');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _metricRow('⭐', '$r Reseñas', Colors.amber, resNow, resPrev),
          const SizedBox(height: 12),
          _metricRow('🔗', '$ref Referencias', Colors.blue, refNow, refPrev),
          const SizedBox(height: 12),
          _metricRow('🏋️', '$g Grupales', Colors.tealAccent, grpNow, grpPrev),
        ],
      ),
    );
  }

  Widget _metricRow(
    String emoji,
    String total,
    Color color,
    Map<String, int> current,
    Map<String, int> previous,
  ) {
    // Unir todos los nombres de ambos meses
    final allNames = {...current.keys, ...previous.keys};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              total,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        if (allNames.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 28),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: allNames.map((name) {
                final cur = current[name] ?? 0;
                final prev = previous[name] ?? 0;
                final diff = cur - prev;
                final deltaStr = diff > 0
                    ? ' +$diff'
                    : diff < 0
                        ? ' $diff'
                        : '';
                final deltaColor = diff > 0
                    ? Colors.greenAccent
                    : diff < 0
                        ? Colors.redAccent
                        : null;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$name ($cur)',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (deltaStr.isNotEmpty)
                          TextSpan(
                            text: deltaStr,
                            style: TextStyle(
                              color: deltaColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildChannelsCard(List<QueryDocumentSnapshot> current) {
    final refs = current.where((d) {
      final data = d.data()! as Map<String, dynamic>;
      return data.safeString('tipo') == 'referencia';
    });
    final channelCounts = <String, int>{};
    for (final doc in refs) {
      final data = doc.data()! as Map<String, dynamic>;
      final canal = data.safeString('canal', defaultValue: 'otro');
      channelCounts[canal] = (channelCounts[canal] ?? 0) + 1;
    }

    if (channelCounts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CANALES DE CAPTACIÓN',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: channelCounts.entries.map((e) {
              final info = _kCanalInfo[e.key];
              return Chip(
                avatar: Icon(info?.icon ?? Icons.help, size: 16),
                label: Text(
                  '${info?.label ?? e.key}: ${e.value}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCrossDerivationsCard(List<QueryDocumentSnapshot> current) {
    final derivaciones = current.where((d) {
      final data = d.data()! as Map<String, dynamic>;
      return data.safeString('tipo') == 'referencia' &&
          data.safeString('canal') == 'derivacion';
    });

    if (derivaciones.isEmpty) return const SizedBox.shrink();

    final pairs = <String, int>{};
    for (final doc in derivaciones) {
      final data = doc.data()! as Map<String, dynamic>;
      final from = data.safeString('profesionalNombre', defaultValue: '?');
      final to = data.safeString('recibeNombre', defaultValue: '?');
      final key = '$from → $to';
      pairs[key] = (pairs[key] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DERIVACIONES CRUZADAS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          ...pairs.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, size: 16, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text(
                    '${e.key}: ${e.value}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrupalButton(List<QueryDocumentSnapshot> current) {
    final myGrupales = current.where((d) {
      final data = d.data()! as Map<String, dynamic>;
      return data.safeString('profesionalId') == widget.userId &&
          data.safeString('tipo') == 'grupal';
    }).length;

    final pendientes = (_kMetaGrupalMensual - myGrupales).clamp(0, _kMetaGrupalMensual);
    final completado = pendientes == 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: completado
              ? [const Color(0xFF2E7D32), const Color(0xFF66BB6A)]
              : [const Color(0xFF009688), const Color(0xFF4DB6AC)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Progress ring
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: myGrupales / _kMetaGrupalMensual,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                  strokeWidth: 6,
                ),
                Text(
                  '$myGrupales',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completado
                      ? 'GRUPALES COMPLETADAS'
                      : '$pendientes GRUPALES PENDIENTES',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  completado
                      ? myGrupales > _kMetaGrupalMensual
                          ? '+${myGrupales - _kMetaGrupalMensual} extra este mes'
                          : 'Objetivo cumplido este mes'
                      : 'Meta: $_kMetaGrupalMensual horas · máx 1/día',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          // Solo mostrar botón en mes actual
          if (_selectedMonth.month == DateTime.now().month &&
              _selectedMonth.year == DateTime.now().year)
            ElevatedButton(
              onPressed: _registrarGrupal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF009688),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'REGISTRAR',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _addResena,
            icon: const Icon(Icons.star, size: 18),
            label: const Text('RESEÑA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _addReferencia,
            icon: const Icon(Icons.link, size: 18),
            label: const Text('REFERENCIA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ── Gráfico trimestral ────────────────────────────────────

  Widget _buildTrimestralChart() {
    return FutureBuilder<List<_MonthData>>(
      future: _loadTrimestralData(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final months = snap.data!;
        final mesesNombres = [
          '',
          'Ene',
          'Feb',
          'Mar',
          'Abr',
          'May',
          'Jun',
          'Jul',
          'Ago',
          'Sep',
          'Oct',
          'Nov',
          'Dic',
        ];

        // Max para escalar barras
        var maxVal = 1;
        for (final m in months) {
          if (m.resenas > maxVal) maxVal = m.resenas;
          if (m.referencias > maxVal) maxVal = m.referencias;
          if (m.grupales > maxVal) maxVal = m.grupales;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EVOLUCIÓN TRIMESTRAL',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 6),
              // Leyenda
              Row(
                children: [
                  _legendDot(Colors.amber.shade700, 'Reseñas'),
                  const SizedBox(width: 16),
                  _legendDot(Colors.blue.shade700, 'Referencias'),
                  const SizedBox(width: 16),
                  _legendDot(const Color(0xFF009688), 'Grupales'),
                ],
              ),
              const SizedBox(height: 16),
              ...months.reversed.map(
                (m) => _chartRow(
                  '${mesesNombres[m.mes]} ${m.anio}',
                  m,
                  maxVal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  Widget _chartRow(String label, _MonthData data, int maxVal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          _barWithTags(data.resenas, maxVal, Colors.amber.shade700, data.resBreakdown),
          const SizedBox(height: 6),
          _barWithTags(data.referencias, maxVal, Colors.blue.shade700, data.refBreakdown),
          const SizedBox(height: 6),
          _barWithTags(data.grupales, maxVal, const Color(0xFF009688), data.grpBreakdown),
        ],
      ),
    );
  }

  Widget _barWithTags(int value, int max, Color color, Map<String, int> breakdown) {
    final fraction = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: Colors.grey.shade100,
                  color: color,
                  minHeight: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 24,
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        if (breakdown.isNotEmpty && _isAdmin)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 3,
              children: breakdown.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${e.key} (${e.value})',
                    style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Future<List<_MonthData>> _loadTrimestralData() async {
    final result = <_MonthData>[];
    for (var i = 2; i >= 0; i--) {
      final target = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - i,
      );
      final docs = await _entriesForMonth(target.month, target.year);

      Map<String, int> breakdown(String tipo) {
        final map = <String, int>{};
        for (final doc in docs) {
          final data = doc.data()! as Map<String, dynamic>;
          if (data.safeString('tipo') != tipo) continue;
          final name = data.safeString('profesionalNombre', defaultValue: '?').split(' ').first;
          map[name] = (map[name] ?? 0) + 1;
        }
        return map;
      }

      int count(String tipo) =>
          docs.where((d) => (d.data()! as Map<String, dynamic>).safeString('tipo') == tipo).length;

      result.add(
        _MonthData(
          mes: target.month,
          anio: target.year,
          resenas: count('resena'),
          referencias: count('referencia'),
          grupales: count('grupal'),
          resBreakdown: breakdown('resena'),
          refBreakdown: breakdown('referencia'),
          grpBreakdown: breakdown('grupal'),
        ),
      );
    }
    return result;
  }
}

// ═══════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════════

class _MonthData {
  const _MonthData({
    required this.mes,
    required this.anio,
    required this.resenas,
    required this.referencias,
    required this.grupales,
    required this.resBreakdown,
    required this.refBreakdown,
    required this.grpBreakdown,
  });
  final int mes;
  final int anio;
  final int resenas;
  final int referencias;
  final int grupales;
  final Map<String, int> resBreakdown;
  final Map<String, int> refBreakdown;
  final Map<String, int> grpBreakdown;
}

class _ProfessionalPoolCard extends StatelessWidget {
  const _ProfessionalPoolCard({
    required this.nombre,
    required this.resenas,
    required this.referencias,
    required this.grupales,
    required this.prevResenas,
    required this.prevReferencias,
    required this.prevGrupales,
  });
  final String nombre;
  final int resenas;
  final int referencias;
  final int grupales;
  final int prevResenas;
  final int prevReferencias;
  final int prevGrupales;

  Widget _delta(int current, int previous) {
    final diff = current - previous;
    if (diff > 0) {
      return Text(
        '+$diff↑',
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      );
    }
    if (diff < 0) {
      return Text(
        '$diff↓',
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      );
    }
    return const Text(
      '0 =',
      style: TextStyle(
        color: Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendientes =
        (_kMetaGrupalMensual - grupales).clamp(0, _kMetaGrupalMensual);
    final grupalProgress =
        (grupales / _kMetaGrupalMensual).clamp(0.0, 1.0);
    final completado = pendientes == 0;

    return Card(
      color: Colors.white.withValues(alpha: 0.92),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _stat('⭐', '$resenas', 'Reseñas', _delta(resenas, prevResenas)),
                const SizedBox(width: 24),
                _stat('🔗', '$referencias', 'Referencias', _delta(referencias, prevReferencias)),
              ],
            ),
            const SizedBox(height: 12),
            // Barra de grupales
            Row(
              children: [
                const Text('🏋️ ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: grupalProgress,
                      backgroundColor: Colors.grey.shade200,
                      color: completado
                          ? Colors.green
                          : grupales >= 2
                              ? Colors.orange
                              : Colors.red,
                      minHeight: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$grupales/$_kMetaGrupalMensual',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                _delta(grupales, prevGrupales),
                if (completado)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.check_circle, color: Colors.green, size: 18),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String emoji, String value, String label, Widget delta) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(width: 6),
        delta,
      ],
    );
  }
}
