import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/features/whatsapp_bot/application/clinic_info_providers.dart';
import 'package:salufit_app/features/whatsapp_bot/domain/clinic_info_model.dart';

const _diasSemana = [
  ('lunes', 'Lunes'),
  ('martes', 'Martes'),
  ('miercoles', 'Miércoles'),
  ('jueves', 'Jueves'),
  ('viernes', 'Viernes'),
  ('sabado', 'Sábado'),
  ('domingo', 'Domingo'),
];

class ClinicInfoTab extends ConsumerWidget {
  const ClinicInfoTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(clinicInfoProvider);
    return infoAsync.when(
      data: (info) => _ClinicInfoForm(info: info),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ClinicInfoForm extends ConsumerStatefulWidget {
  const _ClinicInfoForm({required this.info});
  final ClinicInfo info;

  @override
  ConsumerState<_ClinicInfoForm> createState() => _ClinicInfoFormState();
}

class _ClinicInfoFormState extends ConsumerState<_ClinicInfoForm> {
  late TextEditingController _direccion;
  late TextEditingController _googleMaps;
  late TextEditingController _telefono;
  late TextEditingController _parking;
  late TextEditingController _comoLlegar;
  late TextEditingController _primeraVisita;
  late TextEditingController _bienvenida;
  late Map<String, DayHours?> _horarios;
  late List<ServicioInfo> _servicios;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.info;
    _direccion = TextEditingController(text: i.direccion);
    _googleMaps = TextEditingController(text: i.googleMapsUrl);
    _telefono = TextEditingController(text: i.telefonoRecepcion);
    _parking = TextEditingController(text: i.parking);
    _comoLlegar = TextEditingController(text: i.comoLlegar);
    _primeraVisita = TextEditingController(text: i.primeraVisita);
    _bienvenida = TextEditingController(text: i.bienvenidaNuevoPaciente);
    _horarios = Map<String, DayHours?>.from(i.horarios);
    _servicios = List<ServicioInfo>.from(i.servicios);
  }

  @override
  void dispose() {
    _direccion.dispose();
    _googleMaps.dispose();
    _telefono.dispose();
    _parking.dispose();
    _comoLlegar.dispose();
    _primeraVisita.dispose();
    _bienvenida.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final actions = ref.read(clinicInfoActionsProvider);
      await actions.updateClinicInfo({
        'direccion': _direccion.text.trim(),
        'googleMapsUrl': _googleMaps.text.trim(),
        'telefonoRecepcion': _telefono.text.trim(),
        'parking': _parking.text.trim(),
        'comoLlegar': _comoLlegar.text.trim(),
        'primeraVisita': _primeraVisita.text.trim(),
        'bienvenidaNuevoPaciente': _bienvenida.text.trim(),
        'horarios': _horarios.map(
          (k, v) => MapEntry(
            k,
            v == null ? null : {'abre': v.abre, 'cierra': v.cierra},
          ),
        ),
        'servicios': _servicios
            .map((s) => {
                  'nombre': s.nombre,
                  if (s.precio != null) 'precio': s.precio,
                  if (s.descripcion != null && s.descripcion!.isNotEmpty)
                    'descripcion': s.descripcion,
                })
            .toList(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Información del centro guardada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _section(
            'Horarios habituales',
            Column(
              children: _diasSemana.map((d) {
                final cur = _horarios[d.$1];
                return _DayHoursRow(
                  label: d.$2,
                  hours: cur,
                  onChanged: (h) => setState(() => _horarios[d.$1] = h),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _section(
            'Datos del centro',
            Column(
              children: [
                _field('Dirección', _direccion, maxLines: 2),
                const SizedBox(height: 8),
                _field('URL Google Maps', _googleMaps),
                const SizedBox(height: 8),
                _field('Teléfono de recepción', _telefono),
                const SizedBox(height: 8),
                _field('Parking', _parking, maxLines: 3),
                const SizedBox(height: 8),
                _field('Cómo llegar', _comoLlegar, maxLines: 3),
                const SizedBox(height: 8),
                _field('Instrucciones primera visita', _primeraVisita,
                    maxLines: 3),
                const SizedBox(height: 8),
                _field('Mensaje de bienvenida (paciente nuevo)', _bienvenida,
                    maxLines: 3),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            'Servicios y precios',
            Column(
              children: [
                ..._servicios.asMap().entries.map((e) => _ServicioRow(
                      key: ValueKey('servicio_${e.key}'),
                      servicio: e.value,
                      onChanged: (s) =>
                          setState(() => _servicios[e.key] = s),
                      onDelete: () =>
                          setState(() => _servicios.removeAt(e.key)),
                    )),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir servicio'),
                    onPressed: () => setState(
                        () => _servicios.add(const ServicioInfo())),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
            label: const Text('Guardar cambios'),
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _DayHoursRow extends StatelessWidget {
  const _DayHoursRow({
    required this.label,
    required this.hours,
    required this.onChanged,
  });

  final String label;
  final DayHours? hours;
  final ValueChanged<DayHours?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cerrado = hours == null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label)),
          Switch(
            value: !cerrado,
            onChanged: (open) => onChanged(
              open ? const DayHours() : null,
            ),
          ),
          const SizedBox(width: 8),
          if (!cerrado) ...[
            Expanded(
              child: TextField(
                controller: TextEditingController(text: hours!.abre),
                decoration: const InputDecoration(
                  labelText: 'Abre',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (v) =>
                    onChanged(DayHours(abre: v, cierra: hours!.cierra)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: TextEditingController(text: hours!.cierra),
                decoration: const InputDecoration(
                  labelText: 'Cierra',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (v) =>
                    onChanged(DayHours(abre: hours!.abre, cierra: v)),
              ),
            ),
          ] else
            const Expanded(
                child: Text('Cerrado', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}

class _ServicioRow extends StatefulWidget {
  const _ServicioRow({
    super.key,
    required this.servicio,
    required this.onChanged,
    required this.onDelete,
  });

  final ServicioInfo servicio;
  final ValueChanged<ServicioInfo> onChanged;
  final VoidCallback onDelete;

  @override
  State<_ServicioRow> createState() => _ServicioRowState();
}

class _ServicioRowState extends State<_ServicioRow> {
  late TextEditingController _nombre;
  late TextEditingController _precio;
  late TextEditingController _descripcion;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.servicio.nombre);
    _precio = TextEditingController(
        text: widget.servicio.precio?.toString() ?? '');
    _descripcion =
        TextEditingController(text: widget.servicio.descripcion ?? '');
  }

  @override
  void dispose() {
    _nombre.dispose();
    _precio.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(ServicioInfo(
      nombre: _nombre.text.trim(),
      precio: int.tryParse(_precio.text.trim()),
      descripcion:
          _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _nombre,
              decoration: const InputDecoration(
                labelText: 'Servicio',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _emit(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: TextField(
              controller: _precio,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '€',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _emit(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: TextField(
              controller: _descripcion,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _emit(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: widget.onDelete,
            color: Colors.red.shade400,
          ),
        ],
      ),
    );
  }
}
