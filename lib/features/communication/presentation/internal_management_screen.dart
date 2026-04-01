import 'package:flutter/material.dart';
import 'package:salufit_app/features/communication/presentation/widgets/chat_list_widget.dart';

class InternalManagementScreen extends StatelessWidget {
  const InternalManagementScreen({
    required this.currentUserId,
    required this.userRole,
    this.viewType = 'chat',
    super.key,
  });

  final String currentUserId;
  final String userRole;
  final String viewType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Comunicación de Equipo'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.tealAccent, size: 20),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    'Viendo miembros del equipo (Admin/Profesional) activos.',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ChatListWidget(
              currentUserId: currentUserId,
              isStaffOnly: true,
            ),
          ),
        ],
      ),
    );
  }
}
