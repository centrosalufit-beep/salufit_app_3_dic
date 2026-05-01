import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/core/providers/locale_provider.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/core/utils/localized_field.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/bookings/data/class_repository.dart';
import 'package:salufit_app/features/bookings/providers/booking_providers.dart';
import 'package:salufit_app/l10n/generated/app_localizations.dart';
import 'package:salufit_app/shared/widgets/salufit_header.dart';
import 'package:salufit_app/shared/widgets/salufit_scaffold.dart';

class ClientClassListScreen extends ConsumerStatefulWidget {
  const ClientClassListScreen({
    required this.userId,
    required this.userRole,
    super.key,
    this.initialDate,
  });

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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);
    final localeCode = locale.languageCode;
    final classesAsync = ref.watch(classesStreamProvider);
    final myBookings = ref.watch(myBookingsMapProvider);

    return SalufitScaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          children: [
            SalufitHeader(title: t.classListHeaderTitle),
            _buildCalendarRail(localeCode),
            _buildDateDivider(localeCode),
            Expanded(
              child: classesAsync.when(
                data: (snap) {
                  final filtered = snap.docs.where((d) {
                    final data = d.data()! as Map<String, dynamic>;
                    return _isSameDay(data.safeDateTime('fechaHoraInicio'), _selectedDate);
                  }).toList();
                  if (filtered.isEmpty) {
                    return Center(child: Text(t.classListEmptyDay));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final doc = filtered[i];
                      final data = doc.data()! as Map<String, dynamic>;
                      final localizedName =
                          data.localized('nombre', locale).toUpperCase();
                      final visuals = _getClassVisuals(localizedName.toLowerCase());
                      return _ClassCard(
                        data: data,
                        classId: doc.id,
                        visuals: visuals,
                        localizedName: localizedName,
                        localizedMonitor:
                            data.localized('monitor', locale),
                        isBooked: myBookings.containsKey(doc.id),
                        isProcessing: _processingClassIds.contains(doc.id),
                        onBook: () => _handleReserva(data, doc.id),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (_, __) => Center(child: Text(t.classListLoadErrorMsg)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarRail(String localeCode) {
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
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE', localeCode)
                        .format(date)
                        .toUpperCase()
                        .replaceAll('.', ''),
                    style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 12),
                  ),
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
          );
        },
      ),
    );
  }

  Widget _buildDateDivider(String localeCode) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Text(
          DateFormat('EEEE d MMMM', localeCode).format(_selectedDate).toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      );

  Map<String, dynamic> _getClassVisuals(String nombreLower) {
    final n = nombreLower;
    if (n.contains('meditación') || n.contains('meditacion') || n.contains('meditation')) {
      return {'colors': [const Color(0xFF4A148C), const Color(0xFFAB47BC)], 'bgIcon': Icons.spa};
    }
    if (n.contains('tribu') || n.contains('activa') || n.contains('walk')) {
      return {'colors': [const Color(0xFFE65100), const Color(0xFFFFB74D)], 'bgIcon': Icons.directions_walk};
    }
    if (n.contains('terapéutico') || n.contains('terapeutico') || n.contains('therapeutic')) {
      return {'colors': [const Color(0xFF0D47A1), const Color(0xFF42A5F5)], 'bgIcon': Icons.self_improvement};
    }
    if (n.contains('entrenamiento') || n.contains('training') || n.contains('entraînement') || n.contains('entrainement')) {
      return {'colors': [const Color(0xFFC62828), const Color(0xFFFF5252)], 'bgIcon': Icons.fitness_center};
    }
    if (n.contains('kids') || n.contains('explora') || n.contains('niños') || n.contains('enfants') || n.contains('kinder')) {
      return {'colors': [const Color(0xFF00897B), const Color(0xFF4DB6AC)], 'bgIcon': Icons.escalator_warning};
    }
    return {'colors': [const Color(0xFF009688), const Color(0xFF4DB6AC)], 'bgIcon': Icons.person};
  }

  Future<void> _handleReserva(Map<String, dynamic> data, String id) async {
    if (_processingClassIds.contains(id)) return;
    final t = AppLocalizations.of(context);

    final fechaClase = data.safeDateTime('fechaHoraInicio');
    final horasRestantes = fechaClase.difference(DateTime.now()).inHours;

    if (horasRestantes < 24) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.schedule, color: Colors.orange.shade700, size: 32),
                ),
                const SizedBox(height: 16),
                Text(t.classBookConfirmShortTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  t.classBookConfirmShortMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text(t.commonReturnUpper, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688), padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text(t.classBookUpper, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (confirmar != true) return;
    }

    setState(() => _processingClassIds.add(id));
    try {
      await ref.read(classRepositoryProvider).inscribirUsuario(
            userId: widget.userId,
            userEmail: ref.read(firebaseAuthProvider).currentUser?.email ?? '',
            classId: id,
          );
    } finally {
      if (mounted) setState(() => _processingClassIds.remove(id));
    }
  }
}

class _ClassCard extends ConsumerWidget {
  const _ClassCard({
    required this.data,
    required this.classId,
    required this.visuals,
    required this.localizedName,
    required this.localizedMonitor,
    required this.isBooked,
    required this.isProcessing,
    required this.onBook,
  });

  final Map<String, dynamic> data;
  final String classId;
  final Map<String, dynamic> visuals;
  final String localizedName;
  final String localizedMonitor;
  final bool isBooked;
  final bool isProcessing;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = (visuals['colors'] as List).cast<Color>();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors[0].withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              right: 60,
              top: -10,
              bottom: -10,
              child: Icon(visuals['bgIcon'] as IconData, size: 100, color: Colors.black.withValues(alpha: 0.1)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  _buildTimeSidebar(data.safeDateTime('fechaHoraInicio')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildClassInfo(context)),
                  const SizedBox(width: 6),
                  _buildActionButton(context, colors[0]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSidebar(DateTime start) => Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(DateFormat('HH:mm').format(start),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            Text(DateFormat('HH:mm').format(start.add(const Duration(hours: 1))),
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      );

  Widget _buildClassInfo(BuildContext context) {
    final t = AppLocalizations.of(context);
    final words = localizedName.split(' ');
    final formattedTitle = words.length > 1 ? words.join('\n') : localizedName;
    final monitorDisplay = localizedMonitor.trim().isNotEmpty
        ? localizedMonitor
        : t.classListStaffDefault;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formattedTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, height: 1.1),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${t.classListMonitorLabel}: $monitorDisplay',
          style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Text(
                '${data.safeInt('aforoActual')}/${data.safeInt('aforoMaximo', defaultValue: 12)}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, Color primary) {
    final t = AppLocalizations.of(context);
    final isFull = data.safeInt('aforoActual') >= data.safeInt('aforoMaximo', defaultValue: 12);
    final label = isBooked
        ? t.classBookedUpper
        : (isFull ? t.classFullUpper : t.classBookUpper);
    return ElevatedButton(
      onPressed: (isBooked || isProcessing || isFull) ? null : onBook,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(85, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isProcessing
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
    );
  }
}
