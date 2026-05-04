import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Cierra la sesión automáticamente tras 30 min de inactividad.
/// (El registro horario lo gestiona Clinni externamente; aquí solo logout.)
class SessionShield {
  static Timer? _inactivityTimer;
  static const _timeout = Duration(minutes: 30);

  static void resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeout, _handleLogout);
  }

  static Future<void> _handleLogout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseAuth.instance.signOut();
    debugPrint('🛡️ SessionShield: sesión cerrada por inactividad.');
  }
}
