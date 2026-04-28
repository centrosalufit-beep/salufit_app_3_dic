import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/features/whatsapp_bot/application/whatsapp_bot_providers.dart';
import 'package:salufit_app/features/whatsapp_bot/presentation/widgets/conversation_table_widget.dart';
import 'package:salufit_app/features/whatsapp_bot/presentation/widgets/import_excel_widget.dart';

class WhatsAppBotScreen extends ConsumerWidget {
  const WhatsAppBotScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(whatsappConversationsProvider);
    final upcomingAsync = ref.watch(upcomingAppointmentsProvider);
    final configAsync = ref.watch(botConfigProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Bot WhatsApp'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Top bar: import + status
          Container(
            color: Colors.white.withValues(alpha: 0.95),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const ImportExcelButton(),
                const SizedBox(width: 16),
                upcomingAsync.maybeWhen(
                  data: (list) => _StatPill(
                    label: 'Citas activas',
                    value: '${list.length}',
                    color: AppColors.primary,
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                conversationsAsync.maybeWhen(
                  data: (list) => _StatPill(
                    label: 'Conversaciones',
                    value: '${list.length}',
                    color: Colors.indigo,
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                const Spacer(),
                configAsync.maybeWhen(
                  data: (cfg) => _BotStatusBadge(activo: cfg?['activo'] != false),
                  orElse: () => const _BotStatusBadge(activo: false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Conversations table
          Expanded(
            child: conversationsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Error cargando conversaciones:\n$e',
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (list) => ConversationTableWidget(conversations: list),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}

class _BotStatusBadge extends StatelessWidget {
  const _BotStatusBadge({required this.activo});
  final bool activo;

  @override
  Widget build(BuildContext context) {
    final color = activo ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            activo ? 'Bot ACTIVO' : 'Bot INACTIVO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
