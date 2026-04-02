import 'package:flutter/material.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_class_list_screen.dart';

/// Pantalla de clases para profesionales (solo lectura, sin reservar).
class ProfessionalClassScreen extends StatelessWidget {
  const ProfessionalClassScreen({required this.userId, super.key});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clases Grupales'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ClientClassListScreen(
        userId: userId,
        userRole: 'profesional',
      ),
    );
  }
}
