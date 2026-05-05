import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/features/auth/application/professional_consent_provider.dart';
import 'package:salufit_app/features/auth/presentation/migration_gate.dart';
import 'package:salufit_app/features/auth/presentation/pending_signature_gate.dart';
import 'package:salufit_app/features/auth/presentation/professional_consent_screen.dart';
import 'package:salufit_app/features/auth/presentation/terms_acceptance_screen.dart';
import 'package:salufit_app/features/home/presentation/screens/main_client_dashboard_screen.dart';
import 'package:salufit_app/features/professional/presentation/professional_dashboard_screen.dart';
import 'package:salufit_app/layouts/desktop_scaffold.dart';

class RoleGate extends ConsumerWidget {
  const RoleGate({required this.user, super.key});
  final User user;

  bool get _isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users_app')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ── Caso de error o doc inexistente ───────────────────────
        // Antes esto disparaba `_forceLogout` con SnackBar invisible
        // (el contexto se desmontaba al hacer signOut). Ahora mostramos
        // una pantalla de error explícita con botón visible para que
        // el usuario sepa exactamente qué pasa.
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          debugPrint(
            '🛡️ RoleGate: uid=${user.uid} email=${user.email} '
            'hasError=${snapshot.hasError} hasData=${snapshot.hasData} '
            'exists=${snapshot.data?.exists} error=${snapshot.error}',
          );
          return _RoleGateErrorScreen(
            user: user,
            errorReason: snapshot.hasError
                ? 'Error al consultar tu perfil:\n${snapshot.error}'
                : 'No se ha encontrado tu perfil en la base de datos.\n'
                    'Esto puede pasar si la activación no terminó correctamente.\n\n'
                    'Pide al administrador que verifique:\n'
                    '• Que existe un documento en `users_app` con tu UID:\n'
                    '  ${user.uid}\n'
                    '• Que existe una entrada en `bbdd` con tu número de historia.',
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final role = (data?['rol'] ?? 'cliente').toString().toLowerCase();
        final termsAccepted = data?['termsAccepted'] as bool? ?? false;
        final isDemo = data?['isDemoAccount'] as bool? ?? false;

        debugPrint(
          '🛡️ RoleGate OK: uid=${user.uid} email=${user.email} role=$role '
          'termsAccepted=$termsAccepted isDemo=$isDemo',
        );

        // Clientes deben aceptar términos (salvo cuenta demo)
        if (!termsAccepted && !isDemo && role == 'cliente') {
          return const TermsAcceptanceScreen();
        }

        final isStaff =
            role == 'admin' || role == 'administrador' || role == 'profesional';

        // Función helper: envuelve con MigrationGate (siempre) y
        // PendingSignatureGate (si no es demo).
        Widget wrapChild(Widget child) {
          final protected = isDemo
              ? child
              : PendingSignatureGate(
                  userId: user.uid,
                  userRole: role,
                  child: child,
                );
          return MigrationGate(userId: user.uid, child: protected);
        }

        if (isStaff) {
          // Gate bloqueante: profesionales/admin deben tener firmado el
          // Acuerdo de Confidencialidad Profesional vigente. Si no, se les
          // muestra la pantalla de firma sin posibilidad de saltar.
          // Cuentas demo se eximen para no entorpecer pruebas.
          if (!isDemo) {
            final consentAsync =
                ref.watch(professionalConsentSignedProvider);
            final consentSigned = consentAsync.maybeWhen(
              data: (v) => v,
              orElse: () => null,
            );
            if (consentSigned == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!consentSigned) {
              return const ProfessionalConsentScreen();
            }
          }

          // Mobile: tanto admin como profesional usan el mismo dashboard
          // mobile (Escanear QR + 6 features). En desktop, admin/profesional
          // van al Hub de Windows.
          if (_isMobile) {
            return wrapChild(
              ProfessionalDashboardScreen(
                userId: user.uid,
                userRole: role,
              ),
            );
          }
          return wrapChild(
            DesktopScaffold(userId: user.uid, userRole: role),
          );
        }

        return wrapChild(
          MainClientDashboardScreen(userId: user.uid, userRole: role),
        );
      },
    );
  }
}

/// Pantalla de error visible cuando RoleGate no puede resolver el perfil.
/// Muestra UID y motivo, y botón explícito para volver al login.
class _RoleGateErrorScreen extends StatelessWidget {
  const _RoleGateErrorScreen({
    required this.user,
    required this.errorReason,
  });

  final User user;
  final String errorReason;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No se pudo iniciar sesión',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    errorReason,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Email: ${user.email ?? '(sin email)'}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 280,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('VOLVER AL INICIO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009688),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
