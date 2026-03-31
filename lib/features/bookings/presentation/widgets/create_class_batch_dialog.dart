import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateClassBatchDialog extends StatefulWidget {
  const CreateClassBatchDialog({super.key});
  @override
  State<CreateClassBatchDialog> createState() => _CreateClassBatchDialogState();
}

class _CreateClassBatchDialogState extends State<CreateClassBatchDialog> {
  String? _selectedType;
  final List<TimeOfDay> _selectedTimes = [];
  final List<int> _selectedDays = [];
  bool _isLoading = false;
  bool _hasConflict = false;

  static const int _defaultCapacity = 12;

  final List<String> _classTypes = [
    'Entrenamiento Grupal',
    'Ejercicio Terapéutico',
    'Meditación Grupal',
    'Tribu Activa',
    'Explora Kids',
  ];

  final Map<String, List<String>> _monitorMapping = {
    'Entrenamiento Grupal': ['Silvio'],
    'Ejercicio Terapéutico': ['Álvaro', 'David', 'Ibitissam'],
    'Meditación Grupal': ['Ignacio', 'Noelia'],
    'Tribu Activa': ['Silvio'],
    'Explora Kids': ['David', 'Sara'],
  };

  final List<String> _dayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  int _existingCount = 0;

  Future<void> _checkConflicts() async {
    if (_selectedType == null || _selectedDays.isEmpty) return;
    final now = DateTime.now();
    final snap = await FirebaseFirestore.instance
        .collection('groupClasses')
        .where('nombre', isEqualTo: _selectedType)
        .where('mes', isEqualTo: now.month)
        .where('anio', isEqualTo: now.year)
        .get();
    if (mounted) {
      setState(() {
        _existingCount = snap.docs.length;
        _hasConflict = _existingCount > 0;
      });
    }
  }

  Future<void> _addTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedTimes.isEmpty
          ? const TimeOfDay(hour: 7, minute: 0)
          : _selectedTimes.last.replacing(hour: (_selectedTimes.last.hour + 1) % 24),
    );
    if (t == null) return;

    final exists = _selectedTimes.any((e) => e.hour == t.hour && e.minute == t.minute);
    if (exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ese horario ya esta agregado'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    setState(() {
      _selectedTimes
        ..add(t)
        ..sort((a, b) => a.hour != b.hour ? a.hour.compareTo(b.hour) : a.minute.compareTo(b.minute));
    });
  }

  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _ejecutarGeneracion() async {
    if (_selectedType == null || _selectedDays.isEmpty || _selectedTimes.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final mes = now.month;
      final anio = now.year;
      final monitores = _monitorMapping[_selectedType] ?? [];
      final monitor = monitores.length == 1 ? monitores.first : monitores.join(', ');
      final db = FirebaseFirestore.instance;
      var count = 0;

      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final firstDay = tomorrow;
      final lastDay = DateTime(anio, mes + 1, 0);

      for (var day = firstDay; !day.isAfter(lastDay); day = day.add(const Duration(days: 1))) {
        if (!_selectedDays.contains(day.weekday)) continue;

        for (final time in _selectedTimes) {
          final fechaInicio = DateTime(anio, mes, day.day, time.hour, time.minute);
          final fechaFin = fechaInicio.add(const Duration(hours: 1));

          await db.collection('groupClasses').add({
            'nombre': _selectedType,
            'monitor': monitor,
            'fechaHoraInicio': Timestamp.fromDate(fechaInicio),
            'fechaHoraFin': Timestamp.fromDate(fechaFin),
            'aforoMaximo': _defaultCapacity,
            'aforoActual': 0,
            'activa': true,
            'estado': 'activa',
            'mes': mes,
            'anio': anio,
            'fechaCreacion': FieldValue.serverTimestamp(),
          });
          count++;
          debugPrint('>>> [CLASES] Creada clase $count: ${_formatTime(time)} dia ${day.day}/$mes');
        }
      }

      debugPrint('>>> [CLASES] Total: $count clases de $_selectedType para $mes/$anio');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count clases de $_selectedType creadas'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('>>> [CLASES] ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear clases'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGenerate = _selectedType != null && _selectedDays.isNotEmpty && _selectedTimes.isNotEmpty;

    return AlertDialog(
      title: const Text('Generador de Cuadrante', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TIPO DE CLASE
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Tipo de Clase', border: OutlineInputBorder()),
                items: _classTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) {
                  setState(() => _selectedType = val);
                  _checkConflicts();
                },
              ),
              const SizedBox(height: 16),

              // EQUIPO ASIGNADO
              if (_selectedType != null) ...[
                const Text('Equipo asignado:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 5,
                  children: (_monitorMapping[_selectedType] ?? []).map((m) => Chip(
                    label: Text(m, style: const TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: const Color(0xFF1E293B),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // AFORO
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.people_outline, size: 20, color: Colors.teal),
                    SizedBox(width: 10),
                    Text('Aforo: ', style: TextStyle(fontSize: 13)),
                    Text('12 personas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // HORARIOS
              Row(
                children: [
                  const Text('Horarios:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addTime,
                    icon: const Icon(Icons.add_circle, size: 20, color: Color(0xFF009688)),
                    label: const Text('Agregar hora', style: TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              if (_selectedTimes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Pulsa "Agregar hora" para anadir horarios', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedTimes.map((t) => Chip(
                    label: Text(_formatTime(t), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _selectedTimes.remove(t)),
                    backgroundColor: const Color(0xFF009688),
                    labelStyle: const TextStyle(color: Colors.white),
                    deleteIconColor: Colors.white70,
                  )).toList(),
                ),
              const SizedBox(height: 20),

              // DIAS DE LA SEMANA
              const Text('Dias de repeticion:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final dayNum = index + 1;
                  final isSelected = _selectedDays.contains(dayNum);
                  return FilterChip(
                    label: Text(_dayNames[index], style: TextStyle(color: isSelected ? Colors.white : null, fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => val ? _selectedDays.add(dayNum) : _selectedDays.remove(dayNum));
                      _checkConflicts();
                    },
                    selectedColor: const Color(0xFF009688),
                    checkmarkColor: Colors.white,
                  );
                }),
              ),

              // RESUMEN
              if (canGenerate) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF009688).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF009688).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RESUMEN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF009688), letterSpacing: 1)),
                      const SizedBox(height: 6),
                      Text('$_selectedType', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${_selectedTimes.length} horarios x ${_selectedDays.length} dias/semana', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('Horarios: ${_selectedTimes.map(_formatTime).join(', ')}', style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],

              // AVISO CONFLICTO
              if (_hasConflict) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange)),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Ya hay $_existingCount clases de $_selectedType este mes. Se crearan adicionales.', style: const TextStyle(fontSize: 11, color: Colors.orange))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
        ElevatedButton.icon(
          onPressed: _isLoading || !canGenerate ? null : _ejecutarGeneracion,
          style: ElevatedButton.styleFrom(
            backgroundColor: _hasConflict ? Colors.orange : const Color(0xFF009688),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(_hasConflict ? 'FORZAR GENERACION' : 'GENERAR CUADRANTE', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
