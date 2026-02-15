#!/bin/zsh

HELPER_PATH="lib/features/auth/presentation/activation_screen_helper.dart"

echo "🛠️ Personalizando Pop-up de rescate para usuarios registrados..."

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
            Icon(Icons.account_circle, color: Color(0xFF009688)),
            SizedBox(width: 10),
            Text('Cuenta Detectada', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Parece que ya tienes una cuenta activa con el correo \$email.\n\nSi no recuerdas tu contraseña, no te preocupes. Pulsa el botón de abajo y te enviaremos un enlace para crear una nueva y entrar directamente.',
          style: TextStyle(fontSize: 15),
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
              Navigator.pop(ctx); // Cierra el diálogo
              try {
                // Inicia el proceso de envío de email
                await ref.read(authServiceProvider).sendPasswordResetEmail(email);
                
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('¡Enlace enviado! Revisa tu bandeja de entrada en \$email'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 5),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hubo un problema al enviar el enlace. Inténtalo de nuevo.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('RESTABLECER CONTRASEÑA', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
INNER_EOF

echo "✅ Pop-up personalizado con éxito en: $HELPER_PATH"
