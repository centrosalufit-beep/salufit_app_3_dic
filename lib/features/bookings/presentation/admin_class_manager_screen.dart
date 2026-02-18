import 'package:flutter/material.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_class_list_screen.dart';

class AdminClassManagerScreen extends StatelessWidget {
  const AdminClassManagerScreen({required this.currentUserId, super.key});
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    // Redirigimos a la vista unificada que ahora es funcional para ambos roles
    return ClientClassListScreen(userId: currentUserId, userRole: 'admin');
  }
}
