import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
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
          Semantics(
            label: 'Cerrar sesión',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                await HapticFeedback.mediumImpact();
                await ref.read(authServiceProvider).signOut();
              },
            ),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        children: [
          _card(
            Icons.qr_code_scanner,
            'Escanear QR',
            AppColors.primary,
            _handleScanQr,
          ),
          _card(
            Icons.person_add,
            'Nuevo Paciente',
            AppColors.primary,
            () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AdminCreatePatientScreen(),
              ),
            ),
          ),
          _card(
            Icons.people,
            'Lista Pacientes',
            AppColors.primary,
            () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AdminPatientListScreen(
                  viewerRole: widget.userRole,
                  onUserSelected: (u, n) {},
                ),
              ),
            ),
          ),
          _card(
            Icons.calendar_month,
            'Clases',
            AppColors.primary,
            () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ClientClassListScreen(
                  userId: widget.userId,
                  userRole: widget.userRole,
                ),
              ),
            ),
          ),
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

  Future<void> _handleScanQr() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(builder: (_) => const QRScannerScreen()),
    );
    if (!mounted || scanned == null || scanned.isEmpty) return;

    final scannedUid = scanned.trim();

    // Obtener datos del cliente para mostrar en la confirmación
    final clientDoc = await ref.read(firebaseFirestoreProvider)
        .collection('users_app')
        .doc(scannedUid)
        .get();

    if (!mounted) return;

    if (!clientDoc.exists) {
      _showResult(
        icon: Icons.error_outline,
        color: Colors.red,
        title: 'Cliente no encontrado',
        message: 'El código QR no corresponde a ningún cliente activo.',
      );
      return;
    }

    final data = clientDoc.data()!;
    final nombre = (data['nombreCompleto'] as String?) ??
        (data['nombre'] as String?) ??
        'Cliente';

    // Confirmación antes de consumir token
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.confirmation_number, color: Color(0xFF009688)),
            SizedBox(width: 8),
            Text('Confirmar asistencia'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Consumir 1 token de $nombre?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Se registrará como asistencia sin reserva previa.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009688),
              foregroundColor: Colors.white,
            ),
            child: const Text('Consumir token'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Llamar a la Cloud Function
    try {
      final callable = ref.read(firebaseFunctionsProvider).httpsCallable(
        'consumirTokenPorQR',
      );
      final result = await callable.call<Map<String, dynamic>>({
        'scannedUserId': scannedUid,
      });

      if (!mounted) return;

      final status = result.data['status'] as String?;
      final clientName =
          (result.data['clientName'] as String?) ?? nombre;

      switch (status) {
        case 'SUCCESS':
          await HapticFeedback.mediumImpact();
          final tokensAfter = (result.data['tokensAfter'] as num?)?.toInt() ?? 0;
          _showResult(
            icon: Icons.check_circle,
            color: const Color(0xFF009688),
            title: 'Asistencia registrada',
            message:
                '$clientName — Tokens restantes: $tokensAfter',
          );
        case 'NO_ACTIVE_PASS':
          _showResult(
            icon: Icons.warning_amber,
            color: Colors.orange,
            title: 'Sin bono activo',
            message: '$clientName no tiene un bono activo.',
          );
        case 'NO_TOKENS':
          _showResult(
            icon: Icons.block,
            color: Colors.red,
            title: 'Sin tokens',
            message: '$clientName no tiene tokens disponibles en su bono.',
          );
        case 'USER_NOT_FOUND':
          _showResult(
            icon: Icons.error_outline,
            color: Colors.red,
            title: 'Cliente no encontrado',
            message: 'El QR no corresponde a ningún cliente activo.',
          );
        default:
          _showResult(
            icon: Icons.help_outline,
            color: Colors.grey,
            title: 'Respuesta desconocida',
            message: 'El servidor devolvió un estado no reconocido.',
          );
      }
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      _showResult(
        icon: Icons.error,
        color: Colors.red,
        title: 'Error',
        message: e.message ?? 'No se pudo procesar el escaneo.',
      );
    } catch (e) {
      if (!mounted) return;
      _showResult(
        icon: Icons.error,
        color: Colors.red,
        title: 'Error',
        message: 'No se pudo procesar el escaneo.',
      );
    }
  }

  void _showResult({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
