import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/bookings/data/class_repository.dart';
import 'package:salufit_app/features/bookings/providers/booking_providers.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

class ClassListScreen extends ConsumerStatefulWidget {
  const ClassListScreen({
    required this.userId,
    required this.userRole,
    super.key,
    this.initialDate,
  });

  final String userId;
  final String userRole;
  final DateTime? initialDate;

  @override
  ConsumerState<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends ConsumerState<ClassListScreen> {
  late DateTime _selectedDate;
  final List<DateTime> _calendarDays = <DateTime>[];
  final Set<String> _processingClassIds = <String>{};

  static const Color salufitTeal = Color(0xFF009688);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    if (_selectedDate.weekday == DateTime.sunday) {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    }
    _generateCalendarDays();
  }

  void _generateCalendarDays() {
    _calendarDays.clear();
    final now = DateTime.now();
    for (var i = 0; i < 30; i++) {
      _calendarDays.add(now.add(Duration(days: i)));
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Map<String, dynamic> _getClassVisuals(String nombreClase) {
    final n = nombreClase.toLowerCase();
    if (n.contains('entrenamiento') || n.contains('fuerza')) {
      return <String, dynamic>{
        'colors': [const Color(0xFFC62828), const Color(0xFFFF5252)],
        'bgIcon': Icons.fitness_center,
      };
    }
    if (n.contains('meditación') || n.contains('meditacion')) {
      return <String, dynamic>{
        'colors': [const Color(0xFF4A148C), const Color(0xFFAB47BC)],
        'bgIcon': Icons.spa,
      };
    }
    if (n.contains('tribu') || n.contains('activa')) {
      return <String, dynamic>{
        'colors': [const Color(0xFFE65100), const Color(0xFFFFB74D)],
        'bgIcon': Icons.directions_walk,
      };
    }
    if (n.contains('terapéutico') || n.contains('terapeutico')) {
      return <String, dynamic>{
        'colors': [const Color(0xFF1B5E20), const Color(0xFF66BB6A)],
        'bgIcon': Icons.self_improvement,
      };
    }
    return <String, dynamic>{
      'colors': [const Color(0xFF0D47A1), const Color(0xFF42A5F5)],
      'bgIcon': Icons.accessibility_new,
    };
  }

  Future<void> _handleReserva(Map<String, dynamic> data, String id) async {
    if (_processingClassIds.contains(id)) {
      return;
    }

    final startTime = data.safeDateTime('fechaHoraInicio');
    if (startTime.difference(DateTime.now()).inHours < 24) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Atención', style: TextStyle(color: Colors.red)),
          content: const Text(
            'Quedan menos de 24h. Si reservas no podrás cancelar sin penalización.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('VOLVER'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('RESERVAR'),
            ),
          ],
        ),
      );
      if (confirm != true) {
        return;
      }
    }

    setState(() {
      _processingClassIds.add(id);
    });
    try {
      final repo = ref.read(classRepositoryProvider);
      await repo.inscribirUsuario(
        userId: widget.userId,
        userEmail: FirebaseAuth.instance.currentUser?.email ?? '',
        classId: id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reserva realizada con éxito'),
            backgroundColor: salufitTeal,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingClassIds.remove(id);
        });
      }
    }
  }

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
                    return _isSameDay(
                      data.safeDateTime('fechaHoraInicio'),
                      _selectedDate,
                    );
                  }).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final doc = filtered[i];
                      final data = doc.data()! as Map<String, dynamic>;
                      final visuals =
                          _getClassVisuals(data.safeString('nombre'));
                      final isBooked = myBookings.containsKey(doc.id);

                      return _ClassCard(
                        data: data,
                        classId: doc.id,
                        visuals: visuals,
                        isBooked: isBooked,
                        isProcessing: _processingClassIds.contains(doc.id),
                        onBook: () => _handleReserva(data, doc.id),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: salufitTeal),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Image.asset(
            'assets/logo_salufit.png',
            width: 50,
            errorBuilder: (c, e, s) => const Icon(
              Icons.calendar_today,
              size: 50,
              color: salufitTeal,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLASES GRUPALES',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: salufitTeal,
                  ),
                ),
                Text(
                  'Reserva tu plaza',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarRail() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _calendarDays.length,
        separatorBuilder: (c, i) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = _calendarDays[index];
          final isSelected = _isSameDay(date, _selectedDate);
          final isSunday = date.weekday == DateTime.sunday;
          final diaSemana = DateFormat('EEE', 'es')
              .format(date)
              .replaceAll('.', '')
              .toUpperCase();

          return GestureDetector(
            onTap: () {
              if (!isSunday) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
            child: Opacity(
              opacity: isSunday ? 0.4 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 65,
                decoration: BoxDecoration(
                  color: isSelected ? salufitTeal : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    if (!isSelected && !isSunday)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      diaSemana,
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 25,
            decoration: BoxDecoration(
              color: salufitTeal,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            DateFormat("EEEE d 'DE' MMMM", 'es')
                .format(_selectedDate)
                .toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 60,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 10),
          const Text(
            'No hay clases programadas',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.data,
    required this.classId,
    required this.visuals,
    required this.isBooked,
    required this.isProcessing,
    required this.onBook,
  });

  final Map<String, dynamic> data;
  final String classId;
  final Map<String, dynamic> visuals;
  final bool isBooked;
  final bool isProcessing;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final gradientColors = (visuals['colors'] as List).cast<Color>();
    final fechaInicio = data.safeDateTime('fechaHoraInicio');
    final aforoActual = data.safeInt('aforoActual');
    final aforoMax = data.safeInt('aforoMaximo', defaultValue: 12);
    final isFull = aforoActual >= aforoMax;
    final isPast = fechaInicio.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -25,
              child: Icon(
                visuals['bgIcon'] as IconData,
                size: 170,
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  _buildTimeSidebar(fechaInicio),
                  const SizedBox(width: 15),
                  Expanded(child: _buildClassInfo(aforoActual, aforoMax)),
                  _buildActionButton(isPast, isFull, gradientColors[0]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSidebar(DateTime start) {
    return Container(
      width: 75,
      margin: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('HH:mm').format(start),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            DateFormat('HH:mm').format(start.add(const Duration(hours: 1))),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildClassInfo(int actual, int max) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.safeString('nombre'),
          maxLines: 2,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Monitor: ${data.safeString('monitor', defaultValue: 'Staff')}',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Text(
                '$actual/$max',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(bool isPast, bool isFull, Color primary) {
    final label = isPast
        ? 'CERRADA'
        : (isBooked ? 'RESERVADO' : (isFull ? 'LLENO' : 'RESERVAR'));
    final canPress = !isPast && !isBooked && !isFull && !isProcessing;

    return ElevatedButton(
      onPressed: canPress ? onBook : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(75, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: isProcessing
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: primary),
            )
          : Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
            ),
    );
  }
}
