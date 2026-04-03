import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:salufit_app/core/services/session_shield.dart';
import 'package:salufit_app/features/auth/presentation/login_screen.dart';
import 'package:salufit_app/features/auth/presentation/role_gate.dart';
import 'package:salufit_app/features/auth/presentation/version_gate.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          // VersionGate después de auth (necesita usuario logueado)
          return Listener(
            onPointerDown: (_) => SessionShield.resetTimer(),
            child: VersionGate(child: RoleGate(user: user)),
          );
        }

        return const LoginScreen();
      },
    );
  }
}
