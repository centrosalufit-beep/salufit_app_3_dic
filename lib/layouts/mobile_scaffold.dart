import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/theme/app_colors.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/qr_scanner_screen.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';
import 'package:salufit_app/features/auth/providers/user_profile_provider.dart';
import 'package:salufit_app/features/client_portal/presentation/screens/client_class_list_screen.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_create_patient_screen.dart';
import 'package:salufit_app/features/patient_record/presentation/admin_patient_list_screen.dart';

class MobileScaffold extends ConsumerStatefulWidget {
  const MobileScaffold({required this.userId, required this.userRole, super.key});
  final String userId;
  final String userRole;
  @override
  ConsumerState<MobileScaffold> createState() => _MobileScaffoldState();
}

class _MobileScaffoldState extends ConsumerState<MobileScaffold> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: profileAsync.when(
          data: (u) => Text('Hola, ${u?.nombre ?? "Profesional"}'),
          loading: () => const Text('Cargando...'),
          error: (_, __) => const Text('Salufit Staff'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () => ref.read(authServiceProvider).signOut()
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        children: [
          _card(Icons.qr_code_scanner, 'Escanear QR', AppColors.primary, () => Navigator.push<void>(context, MaterialPageRoute<void>(builder: (_) => const QRScannerScreen()))),
          _card(Icons.person_add, 'Nuevo Paciente', AppColors.primary, () => Navigator.push<void>(context, MaterialPageRoute<void>(builder: (_) => const AdminCreatePatientScreen()))),
          _card(Icons.people, 'Lista Pacientes', AppColors.primary, () => Navigator.push<void>(context, MaterialPageRoute<void>(builder: (_) => AdminPatientListScreen(viewerRole: widget.userRole, onUserSelected: (u, n) {})))),
          _card(Icons.calendar_month, 'Clases', AppColors.primary, () => Navigator.push<void>(context, MaterialPageRoute<void>(builder: (_) => ClientClassListScreen(userId: widget.userId, userRole: widget.userRole)))),
        ],
      ),
    );
  }

  Widget _card(IconData i, String l, Color c, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(i, color: c, size: 40), const SizedBox(height: 10), Text(l)],
        ),
      ),
    );
  }
}
