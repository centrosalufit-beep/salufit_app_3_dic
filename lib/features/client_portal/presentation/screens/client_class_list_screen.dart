import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/bookings/data/class_repository.dart';
import 'package:salufit_app/features/bookings/providers/booking_providers.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

class ClientClassListScreen extends ConsumerStatefulWidget {
  const ClientClassListScreen({required this.userId, required this.userRole, super.key, this.initialDate});
  final String userId;
  final String userRole;
  final DateTime? initialDate;

  @override
  ConsumerState<ClientClassListScreen> createState() => _ClientClassListScreenState();
}

class _ClientClassListScreenState extends ConsumerState<ClientClassListScreen> {
  late DateTime _selectedDate;
  final List<DateTime> _calendarDays = <DateTime>[];
  final Set<String> _processingClassIds = <String>{};
  static const Color salufitTeal = Color(0xFF009688);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    if (_selectedDate.weekday == DateTime.sunday) _selectedDate = _selectedDate.add(const Duration(days: 1));
    _generateCalendarDays();
  }

  void _generateCalendarDays() {
    _calendarDays.clear();
    final now = DateTime.now();
    for (var i = 0; i < 30; i++) {
      _calendarDays.add(now.add(Duration(days: i)));
    }
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesStreamProvider);
    final myBookings = ref.watch(myBookingsMapProvider);

    return SalufitScaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCalendarRail(),
            _buildDateDivider(),
            Expanded(
              child: classesAsync.when(
                data: (snap) {
                  final filtered = snap.docs.where((d) {
                    final data = d.data()! as Map<String, dynamic>;
                    return _isSameDay(data.safeDateTime('fechaHoraInicio'), _selectedDate);
                  }).toList();
                  if (filtered.isEmpty) return const Center(child: Text('No hay clases programadas'));
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final doc = filtered[i];
                      final data = doc.data()! as Map<String, dynamic>;
                      final visuals = _getClassVisuals(data.safeString('nombre'));
                      return _ClassCard(
                        data: data,
                        classId: doc.id,
                        visuals: visuals,
                        isBooked: myBookings.containsKey(doc.id),
                        isProcessing: _processingClassIds.contains(doc.id),
                        onBook: () => _handleReserva(data, doc.id),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: salufitTeal)),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
    child: Row(
      children: [
        Image.asset('assets/logo_salufit.png', width: 50, errorBuilder: (c, e, s) => const Icon(Icons.calendar_today, size: 50, color: salufitTeal)),
        const SizedBox(width: 15),
        const Text('CLASES GRUPALES', style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w900, color: salufitTeal)),
      ],
    ),
  );

  Widget _buildCalendarRail() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _calendarDays.length,
        separatorBuilder: (c, i) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = _calendarDays[index];
          final isSelected = _isSameDay(date, _selectedDate);
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 65,
              decoration: BoxDecoration(color: isSelected ? salufitTeal : Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('EEE', 'es').format(date).toUpperCase().replaceAll('.', ''), style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 12)),
                  Text('${date.day}', style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateDivider() => Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), child: Text(DateFormat("EEEE d 'DE' MMMM", 'es').format(_selectedDate).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)));

  Map<String, dynamic> _getClassVisuals(String nombre) {
    final n = nombre.toLowerCase();
    // 1. Meditación: Violeta + Persona sentada
    if (n.contains('meditación') || n.contains('meditacion')) {
      return {'colors': [const Color(0xFF4A148C), const Color(0xFFAB47BC)], 'bgIcon': Icons.self_improvement};
    }
    // 2. Tribu Activa: Dorado + Persona de pie (Caminando)
    if (n.contains('tribu') || n.contains('activa')) {
      return {'colors': [const Color(0xFFE65100), const Color(0xFFFFB74D)], 'bgIcon': Icons.directions_walk};
    }
    // 3. Ejercicio Terapéutico: Azul + Persona con brazos abiertos
    if (n.contains('terapéutico') || n.contains('terapeutico')) {
      return {'colors': [const Color(0xFF0D47A1), const Color(0xFF42A5F5)], 'bgIcon': Icons.accessibility_new};
    }
    // 4. Entrenamiento: Rojo + Pesas
    if (n.contains('entrenamiento')) {
      return {'colors': [const Color(0xFFC62828), const Color(0xFFFF5252)], 'bgIcon': Icons.fitness_center};
    }
    return {'colors': [const Color(0xFF009688), const Color(0xFF4DB6AC)], 'bgIcon': Icons.person};
  }

  Future<void> _handleReserva(Map<String, dynamic> data, String id) async {
    if (_processingClassIds.contains(id)) return;
    setState(() => _processingClassIds.add(id));
    try {
      await ref.read(classRepositoryProvider).inscribirUsuario(userId: widget.userId, userEmail: FirebaseAuth.instance.currentUser?.email ?? '', classId: id);
    } finally {
      if (mounted) setState(() => _processingClassIds.remove(id));
    }
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.data, required this.classId, required this.visuals, required this.isBooked, required this.isProcessing, required this.onBook});
  final Map<String, dynamic> data;
  final String classId;
  final Map<String, dynamic> visuals;
  final bool isBooked;
  final bool isProcessing;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final colors = (visuals['colors'] as List).cast<Color>();
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: colors[0].withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(right: -15, bottom: -25, child: Icon(visuals['bgIcon'] as IconData, size: 170, color: Colors.black.withValues(alpha: 0.25))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  _buildTimeSidebar(data.safeDateTime('fechaHoraInicio')),
                  const SizedBox(width: 15),
                  Expanded(child: _buildClassInfo()),
                  const SizedBox(width: 8),
                  _buildActionButton(colors[0]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSidebar(DateTime start) => Container(width: 75, padding: const EdgeInsets.symmetric(vertical: 15), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(15)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(DateFormat('HH:mm').format(start), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)), Text(DateFormat('HH:mm').format(start.add(const Duration(hours: 1))), style: const TextStyle(color: Colors.white70, fontSize: 13))]));

  Widget _buildClassInfo() {
    final rawName = data.safeString('nombre').toUpperCase();
    final List<String> words = rawName.split(' ');
    final String formattedTitle = words.length > 1 ? words.join('\n') : rawName;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 65,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formattedTitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, height: 0.95),
              textAlign: TextAlign.start,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('MONITOR: ${data.safeString('monitor', defaultValue: 'STAFF')}', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Text('${data.safeInt('aforoActual')}/${data.safeInt('aforoMaximo', defaultValue: 12)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(Color primary) {
    final bool isFull = data.safeInt('aforoActual') >= data.safeInt('aforoMaximo', defaultValue: 12);
    final label = isBooked ? 'RESERVADO' : (isFull ? 'LLENO' : 'RESERVAR');
    return ElevatedButton(
      onPressed: (isBooked || isProcessing || isFull) ? null : onBook,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: primary, padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(85, 36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: isProcessing ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
    );
  }
}
