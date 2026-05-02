import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/features/admin_dashboard/presentation/qr_scanner_screen.dart';

/// Flujo completo de escaneo QR para staff (admin/profesional, mobile only).
///
/// 1. Abre `QRScannerScreen` para capturar el QR.
/// 2. Busca el cliente en `users_app`.
/// 3. Pide confirmación.
/// 4. Invoca la Cloud Function `consumirTokenPorQR`.
/// 5. Muestra el resultado (success / sin tokens / recientemente escaneado / etc).
///
/// La Cloud Function bloquea automáticamente escaneos duplicados del mismo
/// cliente en menos de 5 min (status `RECENTLY_SCANNED`).
///
/// Reutilizado en `MobileScaffold` y `ProfessionalDashboardScreen`.
Future<void> showQrScanFlow(BuildContext context, WidgetRef ref) async {
  final scanned = await Navigator.push<String>(
    context,
    MaterialPageRoute<String>(builder: (_) => const QRScannerScreen()),
  );
  if (!context.mounted || scanned == null || scanned.isEmpty) return;

  final scannedUid = scanned.trim();

  final clientDoc = await ref
      .read(firebaseFirestoreProvider)
      .collection('users_app')
      .doc(scannedUid)
      .get();

  if (!context.mounted) return;

  if (!clientDoc.exists) {
    _showResult(
      context,
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

  if (confirmed != true || !context.mounted) return;

  try {
    final callable =
        ref.read(firebaseFunctionsProvider).httpsCallable('consumirTokenPorQR');
    final result = await callable.call<Map<String, dynamic>>({
      'scannedUserId': scannedUid,
    });

    if (!context.mounted) return;

    final status = result.data['status'] as String?;
    final clientName = (result.data['clientName'] as String?) ?? nombre;

    switch (status) {
      case 'SUCCESS':
        await HapticFeedback.mediumImpact();
        final tokensAfter =
            (result.data['tokensAfter'] as num?)?.toInt() ?? 0;
        if (!context.mounted) return;
        _showResult(
          context,
          icon: Icons.check_circle,
          color: const Color(0xFF009688),
          title: 'Asistencia registrada',
          message: '$clientName — Tokens restantes: $tokensAfter',
        );
      case 'RECENTLY_SCANNED':
        final secondsAgo =
            (result.data['secondsAgo'] as num?)?.toInt() ?? 0;
        final mins = (secondsAgo / 60).floor();
        final secs = secondsAgo % 60;
        final tiempo =
            mins > 0 ? '${mins}m ${secs}s' : '${secondsAgo}s';
        _showResult(
          context,
          icon: Icons.timer_outlined,
          color: Colors.orange,
          title: 'Ya escaneado hace poco',
          message:
              '$clientName fue registrado hace $tiempo. '
              'Espera 5 minutos para evitar un consumo doble.',
        );
      case 'NO_ACTIVE_PASS':
        _showResult(
          context,
          icon: Icons.warning_amber,
          color: Colors.orange,
          title: 'Sin bono activo',
          message: '$clientName no tiene un bono activo.',
        );
      case 'NO_TOKENS':
        _showResult(
          context,
          icon: Icons.block,
          color: Colors.red,
          title: 'Sin tokens',
          message: '$clientName no tiene tokens disponibles en su bono.',
        );
      case 'USER_NOT_FOUND':
        _showResult(
          context,
          icon: Icons.error_outline,
          color: Colors.red,
          title: 'Cliente no encontrado',
          message: 'El QR no corresponde a ningún cliente activo.',
        );
      default:
        _showResult(
          context,
          icon: Icons.help_outline,
          color: Colors.grey,
          title: 'Respuesta desconocida',
          message: 'El servidor devolvió un estado no reconocido.',
        );
    }
  } on FirebaseFunctionsException catch (e) {
    if (!context.mounted) return;
    _showResult(
      context,
      icon: Icons.error,
      color: Colors.red,
      title: 'Error',
      message: e.message ?? 'No se pudo procesar el escaneo.',
    );
  } catch (_) {
    if (!context.mounted) return;
    _showResult(
      context,
      icon: Icons.error,
      color: Colors.red,
      title: 'Error',
      message: 'No se pudo procesar el escaneo.',
    );
  }
}

void _showResult(
  BuildContext context, {
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
