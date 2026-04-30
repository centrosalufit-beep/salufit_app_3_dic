import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/features/whatsapp_bot/domain/whatsapp_conversation_model.dart';

/// Estados que ya están cerrados; en estos no mostramos el botón
/// "Marcar como resuelta".
const _closedStates = {
  'resuelta',
  'cerrada',
  'no_registrado',
  'reagendar_confirmacion_pendiente',
};

class ConversationDetailDialog extends ConsumerStatefulWidget {
  const ConversationDetailDialog({required this.conversation, super.key});

  final WhatsAppConversation conversation;

  @override
  ConsumerState<ConversationDetailDialog> createState() =>
      _ConversationDetailDialogState();
}

class _ConversationDetailDialogState
    extends ConsumerState<ConversationDetailDialog> {
  bool _closing = false;

  Future<void> _markResolved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _closing = true);
    try {
      await FirebaseFirestore.instance
          .collection('whatsapp_conversations')
          .doc(widget.conversation.id)
          .update({
        'estado': 'resuelta',
        'resultado': 'cerrada_manualmente',
        'cerradaPor': user.uid,
        'cerradaEn': FieldValue.serverTimestamp(),
        'fechaUltimaInteraccion': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversación marcada como resuelta')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _closing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final c = widget.conversation;
    final canClose = !_closedStates.contains(c.estado);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.pacienteNombre.isNotEmpty
                              ? c.pacienteNombre
                              : '(sin nombre)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          c.pacienteTelefono,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Metadata strip
            Container(
              color: AppColors.primary.withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _Chip(
                    label: 'Tipo',
                    value: c.tipo,
                  ),
                  _Chip(
                    label: 'Estado',
                    value: c.estado,
                    color: _stateColor(c.estado),
                  ),
                  if (c.intencionDetectada != null)
                    _Chip(
                      label: 'Intención',
                      value: c.intencionDetectada!,
                    ),
                  if (c.profesional.isNotEmpty)
                    _Chip(
                      label: 'Profesional',
                      value: c.profesional,
                    ),
                  if (c.fechaCita != null)
                    _Chip(
                      label: 'Cita',
                      value: dateFmt.format(c.fechaCita!),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Mensajes
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: c.mensajes.length,
                itemBuilder: (context, i) {
                  final m = c.mensajes[i];
                  final isBot = m.rol == 'bot';
                  return Align(
                    alignment:
                        isBot ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.55,
                      ),
                      decoration: BoxDecoration(
                        color: isBot
                            ? Colors.grey.shade200
                            : AppColors.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: Radius.circular(isBot ? 4 : 14),
                          bottomRight: Radius.circular(isBot ? 14 : 4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isBot
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                        children: [
                          Text(
                            m.texto,
                            style: TextStyle(
                              color: isBot ? Colors.black87 : Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          if (m.timestamp != null)
                            Text(
                              DateFormat('HH:mm').format(m.timestamp!),
                              style: TextStyle(
                                color: isBot ? Colors.black45 : Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Footer info + acción cerrar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      c.resultado != null
                          ? 'Resultado: ${c.resultado}'
                          : 'Sin resultado registrado',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (canClose)
                    ElevatedButton.icon(
                      onPressed: _closing ? null : _markResolved,
                      icon: _closing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Marcar resuelta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _stateColor(String estado) {
    switch (estado) {
      case 'resuelta':
      case 'cerrada':
        return Colors.green;
      case 'escalada':
      case 'timeout_escalada':
        return Colors.red;
      case 'esperando_respuesta_boton':
      case 'esperando_respuesta_boton_2':
      case 'esperando_respuesta_boton_reagendar':
        return Colors.orange;
      case 'activa':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10,
          color: c,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
