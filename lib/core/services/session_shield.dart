import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SessionShield {
  static Timer? _inactivityTimer;
  static const _timeout = Duration(minutes: 30);

  static void resetTimer() {
    _inactivityTimer?.cancel();
    // FIX: Tear-off (unnecessary_lambdas)
    _inactivityTimer = Timer(_timeout, _handleLogout);
  }

  static void _handleLogout() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseAuth.instance.signOut();
      debugPrint('🛡️ SessionShield: Sesión cerrada por inactividad.');
    }
  }
}
