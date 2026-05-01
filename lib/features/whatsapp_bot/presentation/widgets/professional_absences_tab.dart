import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/features/whatsapp_bot/application/clinic_info_providers.dart';
import 'package:salufit_app/features/whatsapp_bot/domain/clinic_info_model.dart';

class ProfessionalAbsencesTab extends ConsumerWidget {
  const ProfessionalAbsencesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final absencesAsync = ref.watch(professionalAbsencesProvider);
    return absencesAsync.when(
      data: (absences) => _AbsencesList(absences: absences),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _AbsencesList extends ConsumerWidget {
  const _AbsencesList({required this.absences});
  final List<ProfessionalAbsence> absences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('d MMM yyyy', 'es');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${absences.length} ausencia(s) activa(s) o futura(s). '
                  'El generador de slots las descontará automáticamente.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Añadir ausencia'),
                onPressed: () => _showAbsenceDialog(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: absences.isEmpty
              ? Center(
                  child: Text(
                    'Sin ausencias registradas',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : ListView.separated(
                  itemCount: absences.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final a = absences[i];
                    final desdeStr =
                        a.desde != null ? fmt.format(a.desde!) : '?';
                    final hastaStr =
                        a.hasta != null ? fmt.format(a.hasta!) : '?';
                    return ListTile(
                      leading: const Icon(Icons.event_available,
                          color: Colors.orange),
                      title: Text(a.profesionalNombre.isNotEmpty
                          ? a.profesionalNombre
                          : a.profesionalId),
                      subtitle: Text(
                          'Del $desdeStr al $hastaStr · ${a.motivo}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () => _confirmDelete(context, ref, a),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProfessionalAbsence a,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Borrar ausencia'),
        content: Text(
            '¿Borrar la ausencia de ${a.profesionalNombre} (${a.motivo})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(clinicInfoActionsProvider).deleteAbsence(a.id);
    }
  }

  Future<void> _showAbsenceDialog(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(clinicInfoActionsProvider);
    final pros = await ref.read(professionalsListProvider.future);
    if (pros.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay profesionales en professional_schedules'),
          ),
        );
      }
      return;
    }
    var proId = pros.first['id'] as String?;
    var proNombre = pros.first['nombre'] as String;
    DateTime? desde;
    DateTime? hasta;
    final motivoCtl = TextEditingController();

    if (!context.mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (sbCtx, setState) {
          return AlertDialog(
            title: const Text('Nueva ausencia'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: proId,
                    decoration: const InputDecoration(
                      labelText: 'Profesional',
                      border: OutlineInputBorder(),
                    ),
                    items: pros
                        .map((p) => DropdownMenuItem<String>(
                              value: p['id'] as String,
                              child: Text(p['nombre'] as String),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() {
                      proId = v;
                      proNombre = pros.firstWhere(
                          (p) => p['id'] == v)['nombre'] as String;
                    }),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(desde == null
                              ? 'Desde'
                              : DateFormat('d MMM yyyy', 'es')
                                  .format(desde!)),
                          leading: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: sbCtx,
                              initialDate: desde ?? DateTime.now(),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 30)),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => desde = picked);
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(hasta == null
                              ? 'Hasta'
                              : DateFormat('d MMM yyyy', 'es')
                                  .format(hasta!)),
                          leading: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: sbCtx,
                              initialDate: hasta ??
                                  desde ??
                                  DateTime.now(),
                              firstDate: desde ?? DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => hasta = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: motivoCtl,
                    decoration: const InputDecoration(
                      labelText: 'Motivo (vacaciones, baja, formación...)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: (proId == null ||
                        desde == null ||
                        hasta == null ||
                        motivoCtl.text.trim().isEmpty)
                    ? null
                    : () async {
                        await actions.addAbsence(
                          profesionalId: proId!,
                          profesionalNombre: proNombre,
                          desde: DateTime(desde!.year, desde!.month,
                              desde!.day),
                          hasta: DateTime(hasta!.year, hasta!.month,
                              hasta!.day, 23, 59),
                          motivo: motivoCtl.text.trim(),
                        );
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx, true);
                        }
                      },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
    if ((saved ?? false) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ausencia añadida')),
      );
    }
  }
}
