import 'package:flutter/material.dart';

/// Placeholder para Fase B. Mostrará leads que escribieron al bot,
/// pre-fichados en `clinni_patients_pending` por el flujo de onboarding.
class LeadsPendingTab extends StatelessWidget {
  const LeadsPendingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_alt, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Bandeja de leads — Fase B en desarrollo',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
