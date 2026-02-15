#!/bin/zsh

HELPER_PATH="lib/features/auth/presentation/activation_screen_helper.dart"

echo "🛠️ Generando implementación robusta en: $HELPER_PATH"

cat <<INNER_EOF > $HELPER_PATH
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';

class ActivationUIHelper {
  static void showAlreadyRegisteredDialog(BuildContext context, WidgetRef ref, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF009688)),
            SizedBox(width: 10),
            Text('Cuenta ya activa'),
          ],
        ),
        content: Text(
          'El correo $email ya está registrado en Salufit.\n\nSi no recuerdas tu contraseña, haz clic abajo para recibir un enlace de recuperación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009688),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Cerrar diálogo
              try {
                await ref.read(authServiceProvider).sendPasswordResetEmail(email);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Enlace enviado a $email'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error al enviar el enlace. Inténtalo de nuevo.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('RECUPERAR CONTRASEÑA', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
INNER_EOF

echo "✅ Helper actualizado correctamente."
echo "🚀 Ahora ejecuta: flutter clean && flutter run"
