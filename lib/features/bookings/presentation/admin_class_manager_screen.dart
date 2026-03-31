import 'package:flutter/material.dart';
import 'package:salufit_app/features/bookings/presentation/widgets/create_class_batch_dialog.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_class_list_screen.dart';

class AdminClassManagerScreen extends StatelessWidget {
  const AdminClassManagerScreen({required this.currentUserId, super.key});
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) => const CreateClassBatchDialog(),
        ),
        backgroundColor: const Color(0xFF009688),
        icon: const Icon(Icons.calendar_month, color: Colors.white),
        label: const Text(
          'GENERAR CUADRANTE',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ClientClassListScreen(userId: currentUserId, userRole: 'admin'),
    );
  }
}
