import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';

class ActivationUIHelper {
  static void showAlreadyRegisteredDialog(BuildContext context, WidgetRef ref, String email) {
    const salufitTeal = Color(0xFF009688);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('¡Ya eres parte de Salufit!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: salufitTeal, size: 50),
            const SizedBox(height: 15),
            Text(
              'Hemos detectado que tu cuenta ($email) ya está activa.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              '¿Necesitas que te enviemos un enlace para crear una nueva contraseña y acceder ahora?',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: salufitTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authServiceProvider).sendPasswordResetEmail(email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Enlace enviado. Revisa tu email.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context); // Volver al login
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al enviar el correo')),
                  );
                }
              }
            },
            child: const Text('SÍ, ENVIAR ENLACE'),
          ),
        ],
      ),
    );
  }
}
