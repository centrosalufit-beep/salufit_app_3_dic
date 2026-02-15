#!/bin/zsh

HELPER_PATH="lib/features/auth/presentation/activation_screen_helper.dart"

# Verificar si la carpeta existe antes de escribir
mkdir -p lib/features/auth/presentation/

echo "🎨 Sincronizando diseño del Pop-up en la ruta correcta..."

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
        title: const Text('¡Hola de nuevo!', style: TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold)),
        content: Text('Tu cuenta con el correo $email ya está activa.\n\n¿Quieres recibir un enlace para generar una nueva contraseña y entrar ahora?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('AHORA NO', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009688),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).sendPasswordResetEmail(email);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Enlace de recuperación enviado a $email'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('SÍ, ENVIAR ENLACE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
INNER_EOF

echo "✅ UI Sincronizada: $HELPER_PATH"
