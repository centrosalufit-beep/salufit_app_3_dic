#!/bin/zsh

HELPER_PATH="lib/features/auth/presentation/activation_screen_helper.dart"

echo "🎨 Sincronizando diseño del Pop-up de activación..."

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
        title: const Text('Usuario ya registrado', style: TextStyle(color: Color(0xFF009688))),
        content: Text('La cuenta con el correo $email ya está activa.\n\n¿Quieres que te enviemos un enlace para generar una nueva contraseña?'),
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
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).sendPasswordResetEmail(email);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Enlace enviado a $email'), backgroundColor: Colors.green)
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

echo "✅ UI Sincronizada correctamente."
