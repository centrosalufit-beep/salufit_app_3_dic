import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/features/auth/presentation/pending_signature_gate.dart';
import 'package:salufit_app/features/auth/presentation/terms_acceptance_screen.dart';
import 'package:salufit_app/features/home/presentation/screens/main_client_dashboard_screen.dart';
import 'package:salufit_app/features/professional/presentation/professional_dashboard_screen.dart';
import 'package:salufit_app/layouts/desktop_scaffold.dart';

class RoleGate extends StatelessWidget {
  const RoleGate({required this.user, super.key});
  final User user;

  bool get _isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Widget build(BuildContext context) {
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

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          debugPrint(
            '🛡️ RoleGate: Error de acceso o perfil inexistente. Forzando Logout.',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _forceLogout(context);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final role = (data?['rol'] ?? 'cliente').toString().toLowerCase();
        final termsAccepted = data?['termsAccepted'] as bool? ?? false;
        final isDemo = data?['isDemoAccount'] as bool? ?? false;

        // Clientes deben aceptar términos (salvo cuenta demo)
        if (!termsAccepted && !isDemo && role == 'cliente') {
          return const TermsAcceptanceScreen();
        }

        final isStaff =
            role == 'admin' || role == 'administrador' || role == 'profesional';

        // Función helper para envolver con o sin PendingSignatureGate
        Widget wrapChild(Widget child) {
          if (isDemo) return child; // Demo salta firmas
          return PendingSignatureGate(
            userId: user.uid,
            userRole: role,
            child: child,
          );
        }

        if (isStaff) {
          if (_isMobile && role == 'profesional') {
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

  Future<void> _forceLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu sesión ha caducado o el perfil no es válido. '
            'Por favor, identifícate de nuevo.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
