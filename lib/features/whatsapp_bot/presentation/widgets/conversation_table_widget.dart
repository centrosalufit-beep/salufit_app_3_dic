import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/features/whatsapp_bot/domain/whatsapp_conversation_model.dart';
import 'package:salufit_app/features/whatsapp_bot/presentation/widgets/conversation_detail_dialog.dart';

const _closedStates = {
  'resuelta',
  'cerrada',
  'no_registrado',
};

class ConversationTableWidget extends StatefulWidget {
  const ConversationTableWidget({required this.conversations, super.key});

  final List<WhatsAppConversation> conversations;

  @override
  State<ConversationTableWidget> createState() =>
      _ConversationTableWidgetState();
}

class _ConversationTableWidgetState extends State<ConversationTableWidget> {
  String? _filterEstado;
  String? _filterIntencion;
  String _searchQuery = '';
  bool _onlyActive = false;

  List<WhatsAppConversation> get _filtered {
    final q = _searchQuery.trim().toLowerCase();
    return widget.conversations.where((c) {
      if (_filterEstado != null && c.estado != _filterEstado) return false;
      if (_filterIntencion != null && c.intencionDetectada != _filterIntencion) {
        return false;
      }
      if (_onlyActive && _closedStates.contains(c.estado)) return false;
      if (q.isNotEmpty) {
        final hay = '${c.pacienteNombre} ${c.pacienteTelefono}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final estados = widget.conversations.map((c) => c.estado).toSet().toList()
      ..sort();
    final intenciones = widget.conversations
        .map((c) => c.intencionDetectada)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: TextField(
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    hintText: 'Buscar paciente o teléfono',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              _filterDropdown(
                label: 'Estado',
                value: _filterEstado,
                options: estados,
                onChanged: (v) => setState(() => _filterEstado = v),
              ),
              _filterDropdown(
                label: 'Intención',
                value: _filterIntencion,
                options: intenciones,
                onChanged: (v) => setState(() => _filterIntencion = v),
              ),
              FilterChip(
                label: const Text('Solo activas'),
                selected: _onlyActive,
                onSelected: (v) => setState(() => _onlyActive = v),
                selectedColor: AppColors.primary.withValues(alpha: 0.18),
                checkmarkColor: AppColors.primary,
              ),
              if (_filterEstado != null ||
                  _filterIntencion != null ||
                  _onlyActive ||
                  _searchQuery.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _filterEstado = null;
                    _filterIntencion = null;
                    _onlyActive = false;
                    _searchQuery = '';
                  }),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Limpiar'),
                ),
              Text(
                '${filtered.length}/${widget.conversations.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildTable(filtered)),
      ],
    );
  }

  Widget _filterDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<String?>(
        key: ValueKey('dropdown_${label}_${value ?? 'null'}'),
        initialValue: value,
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        items: [
          const DropdownMenuItem<String?>(
            child: Text('Todas'),
          ),
          ...options.map(
            (e) => DropdownMenuItem<String?>(
              value: e,
              child: Text(e, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTable(List<WhatsAppConversation> conversations) {
    if (conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.smart_toy, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                widget.conversations.isEmpty
                    ? 'Sin conversaciones aún'
                    : 'Ningún resultado con los filtros activos',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                widget.conversations.isEmpty
                    ? 'El bot las irá registrando aquí cuando los pacientes interactúen.'
                    : 'Cambia los filtros o pulsa "Limpiar".',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final dateFmt = DateFormat('dd/MM HH:mm');
    final fullFmt = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.05)),
          columns: const [
            DataColumn(label: Text('Paciente')),
            DataColumn(label: Text('Teléfono')),
            DataColumn(label: Text('Tipo')),
            DataColumn(label: Text('Intención')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Profesional')),
            DataColumn(label: Text('Cita')),
            DataColumn(label: Text('Última actividad')),
          ],
          rows: conversations
              .map(
                (c) => DataRow(
                  onSelectChanged: (_) => showDialog<void>(
                    context: context,
                    builder: (_) => ConversationDetailDialog(conversation: c),
                  ),
                  cells: [
                    DataCell(Text(
                      c.pacienteNombre.isEmpty
                          ? '(sin nombre)'
                          : c.pacienteNombre,
                    )),
                    DataCell(Text(_formatPhone(c.pacienteTelefono))),
                    DataCell(_TypeBadge(c.tipo)),
                    DataCell(_IntentBadge(c.intencionDetectada)),
                    DataCell(_StateBadge(c.estado)),
                    DataCell(Text(c.profesional)),
                    DataCell(Text(
                      c.fechaCita != null ? fullFmt.format(c.fechaCita!) : '—',
                    )),
                    DataCell(Text(
                      c.fechaUltimaInteraccion != null
                          ? dateFmt.format(c.fechaUltimaInteraccion!)
                          : '—',
                    )),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String _formatPhone(String raw) {
    if (raw.length < 4) return raw;
    return '••• ${raw.substring(raw.length - 6)}';
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge(this.tipo);
  final String tipo;

  @override
  Widget build(BuildContext context) {
    final isReminder = tipo == 'recordatorio';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isReminder ? Colors.blue : Colors.orange).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isReminder ? 'Recordatorio' : 'Iniciado',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isReminder ? Colors.blue.shade700 : Colors.orange.shade800,
        ),
      ),
    );
  }
}

class _IntentBadge extends StatelessWidget {
  const _IntentBadge(this.intent);
  final String? intent;

  @override
  Widget build(BuildContext context) {
    if (intent == null || intent!.isEmpty) {
      return Text('—', style: TextStyle(color: Colors.grey.shade400));
    }
    final color = _intentColor(intent!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        intent!,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _intentColor(String i) {
    switch (i) {
      case 'confirmar':
        return Colors.green.shade700;
      case 'cancelar':
        return Colors.red.shade700;
      case 'reagendar':
        return Colors.orange.shade800;
      case 'consulta':
        return Colors.blue.shade700;
      case 'escalate':
        return Colors.purple.shade700;
      case 'fuera_horario':
        return Colors.grey.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge(this.estado);
  final String estado;

  @override
  Widget build(BuildContext context) {
    final color = _stateColor(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _stateColor(String estado) {
    switch (estado) {
      case 'resuelta':
      case 'cerrada':
        return Colors.green.shade700;
      case 'escalada':
      case 'timeout_escalada':
        return Colors.red.shade700;
      case 'esperando_respuesta_boton':
      case 'esperando_respuesta_boton_2':
      case 'esperando_respuesta_boton_reagendar':
        return Colors.orange.shade800;
      case 'activa':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}
