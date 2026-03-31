import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/features/auth/presentation/pending_signature_gate.dart';
import 'package:salufit_app/features/auth/presentation/terms_acceptance_screen.dart';
import 'package:salufit_app/features/home/presentation/screens/main_client_dashboard_screen.dart';
import 'package:salufit_app/layouts/desktop_scaffold.dart';

class RoleGate extends StatelessWidget {
  const RoleGate({required this.user, super.key});
  final User user;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users_app').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          debugPrint('🛡️ RoleGate: Error de acceso o perfil inexistente. Forzando Logout.');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _forceLogout(context);
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final role = (data?['rol'] ?? 'cliente').toString().toLowerCase();
        final termsAccepted = data?['termsAccepted'] as bool? ?? false;

        // Clientes deben aceptar terminos antes de acceder
        if (!termsAccepted && role == 'cliente') {
          return const TermsAcceptanceScreen();
        }

        if (role == 'admin' || role == 'administrador' || role == 'profesional') {
          return PendingSignatureGate(
            userId: user.uid,
            userRole: role,
            child: DesktopScaffold(userId: user.uid, userRole: role),
          );
        }

        return PendingSignatureGate(
          userId: user.uid,
          userRole: role,
          child: MainClientDashboardScreen(userId: user.uid, userRole: role),
        );
      },
    );
  }

  // FIX: Future<void> en lugar de void (avoid_void_async)
  Future<void> _forceLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu sesión ha caducado o el perfil no es válido. Por favor, identifícate de nuevo.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
