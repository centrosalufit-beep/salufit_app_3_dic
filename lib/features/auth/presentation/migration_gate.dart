import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/config/app_config.dart';
import 'package:salufit_app/core/providers/firebase_providers.dart';
import 'package:salufit_app/features/auth/presentation/migration/date_of_birth_dialog.dart';
import 'package:salufit_app/features/auth/presentation/migration/granular_consent_dialog.dart';
import 'package:salufit_app/features/auth/presentation/migration/password_migration_dialog.dart';

/// Gate que se interpone entre RoleGate y el contenido de la app.
///
/// Verifica que el usuario cumpla los requisitos de seguridad/legal/RGPD
/// actuales (contraseña robusta, edad, consentimiento granular vigente).
///
/// Si falta alguno, muestra un popup obligatorio que no se puede cerrar
/// hasta que el usuario lo complete. Cuentas demo se saltan estos controles.
class MigrationGate extends ConsumerStatefulWidget {
  const MigrationGate({
    required this.userId,
    required this.child,
    super.key,
  });

  final String userId;
  final Widget child;

  @override
  ConsumerState<MigrationGate> createState() => _MigrationGateState();
}

class _MigrationGateState extends ConsumerState<MigrationGate> {
  bool _checking = true;
  bool _hasPendingMigrations = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runMigrations());
  }

  Future<void> _runMigrations() async {
    try {
      final doc = await ref
          .read(firebaseFirestoreProvider)
          .collection('users_app')
          .doc(widget.userId)
          .get();

      if (!mounted) return;

      final data = doc.data() ?? const <String, dynamic>{};

      // Cuentas demo saltan todas las migraciones
      if (data['isDemoAccount'] == true) {
        setState(() => _checking = false);
        return;
      }

      // Solo aplica a clientes. Staff tiene gestión externa.
      final rol = (data['rol'] as String? ?? '').toLowerCase();
      if (rol != AppConfig.rolCliente) {
        setState(() => _checking = false);
        return;
      }

      final pendings = <Future<bool> Function()>[];

      // 1. Contraseña robusta
      if (data['passwordUpdated'] != true) {
        pendings.add(() async {
          final completed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const PasswordMigrationDialog(),
          );
          return completed ?? false;
        });
      }

      // 2. Fecha de nacimiento (validación de edad legal)
      if (data['dateOfBirth'] == null) {
        pendings.add(() async {
          final completed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const DateOfBirthDialog(),
          );
          return completed ?? false;
        });
      }

      // 3. Consentimiento granular con versión actual
      final consentVersion = data['consentVersion'] as String?;
      if (consentVersion != AppConfig.consentVersionActual) {
        pendings.add(() async {
          final completed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => const GranularConsentDialog(),
          );
          return completed ?? false;
        });
      }

      if (pendings.isEmpty) {
        setState(() => _checking = false);
        return;
      }

      setState(() => _hasPendingMigrations = true);

      // Ejecutar popups secuencialmente
      for (final pending in pendings) {
        if (!mounted) return;
        final ok = await pending();
        if (!ok) {
          // Si el usuario abandona, cerrar sesión por seguridad
          if (!mounted) return;
          await Navigator.of(context).maybePop();
          return;
        }
      }

      if (mounted) setState(() => _checking = false);
    } catch (e) {
      debugPrint('MigrationGate error: $e');
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _hasPendingMigrations
                    ? 'Actualizando tu cuenta para cumplir la normativa...'
                    : 'Verificando tu cuenta...',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }
    return widget.child;
  }
}
