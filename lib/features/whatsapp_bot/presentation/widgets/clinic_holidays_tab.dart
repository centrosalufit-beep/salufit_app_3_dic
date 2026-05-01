import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/features/whatsapp_bot/application/clinic_info_providers.dart';
import 'package:salufit_app/features/whatsapp_bot/domain/clinic_info_model.dart';

class ClinicHolidaysTab extends ConsumerWidget {
  const ClinicHolidaysTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(clinicHolidaysProvider);
    return holidaysAsync.when(
      data: (holidays) => _HolidaysList(holidays: holidays),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _HolidaysList extends ConsumerWidget {
  const _HolidaysList({required this.holidays});
  final List<ClinicHoliday> holidays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('EEE, d MMM yyyy', 'es');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${holidays.length} día(s) cerrados próximos. '
                  'El bot informará a los pacientes que pregunten.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Añadir festivo'),
                onPressed: () => _showHolidayDialog(context, ref, null),
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
          child: holidays.isEmpty
              ? Center(
                  child: Text(
                    'Sin festivos configurados',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : ListView.separated(
                  itemCount: holidays.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final h = holidays[i];
                    DateTime? parsed;
                    try {
                      parsed = DateTime.parse(h.fecha);
                    } catch (_) {}
                    final fechaTxt =
                        parsed != null ? fmt.format(parsed) : h.fecha;
                    return ListTile(
                      leading: _tipoIcon(h.tipo),
                      title: Text(fechaTxt),
                      subtitle: Text('${h.motivo} · ${h.tipo}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () =>
                                _showHolidayDialog(context, ref, h),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            onPressed: () => _confirmDelete(context, ref, h),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _tipoIcon(String tipo) {
    switch (tipo) {
      case 'cerrado_excepcional':
        return const Icon(Icons.event_busy, color: Colors.orange);
      case 'horario_reducido':
        return const Icon(Icons.access_time, color: Colors.blue);
      default:
        return const Icon(Icons.celebration, color: Colors.red);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ClinicHoliday h,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Borrar festivo'),
        content: Text('¿Borrar "${h.motivo}" del ${h.fecha}?'),
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
    if (ok == true) {
      await ref.read(clinicInfoActionsProvider).deleteHoliday(h.fecha);
    }
  }

  Future<void> _showHolidayDialog(
    BuildContext context,
    WidgetRef ref,
    ClinicHoliday? existing,
  ) async {
    final actions = ref.read(clinicInfoActionsProvider);
    DateTime? fecha = existing != null ? DateTime.tryParse(existing.fecha) : null;
    final motivoCtl =
        TextEditingController(text: existing?.motivo ?? '');
    String tipo = existing?.tipo ?? 'festivo';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (sbCtx, setState) {
          return AlertDialog(
            title:
                Text(existing == null ? 'Nuevo festivo' : 'Editar festivo'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(fecha == null
                        ? 'Selecciona fecha'
                        : DateFormat('EEEE d MMMM yyyy', 'es')
                            .format(fecha!)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: sbCtx,
                        initialDate: fecha ?? DateTime.now(),
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 30)),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 730)),
                      );
                      if (picked != null) setState(() => fecha = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: motivoCtl,
                    decoration: const InputDecoration(
                      labelText: 'Motivo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'festivo', child: Text('Festivo')),
                      DropdownMenuItem(
                          value: 'cerrado_excepcional',
                          child: Text('Cerrado excepcional')),
                      DropdownMenuItem(
                          value: 'horario_reducido',
                          child: Text('Horario reducido')),
                    ],
                    onChanged: (v) => setState(() => tipo = v ?? 'festivo'),
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
                onPressed: fecha == null || motivoCtl.text.trim().isEmpty
                    ? null
                    : () async {
                        final iso = fecha!.toIso8601String().substring(0, 10);
                        await actions.upsertHoliday(ClinicHoliday(
                          fecha: iso,
                          motivo: motivoCtl.text.trim(),
                          tipo: tipo,
                        ));
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
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Festivo guardado')),
      );
    }
  }
}
