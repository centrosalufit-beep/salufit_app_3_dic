import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

    // Auto clock-out si tiene fichaje activo
    try {
      final lastRecord = await FirebaseFirestore.instance
          .collection('timeClockRecords')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (lastRecord.docs.isNotEmpty &&
          lastRecord.docs.first.get('type') == 'IN') {
        // Reutilizar userName del registro IN si existe
        final lastData = lastRecord.docs.first.data();
        final userName =
            (lastData['userName'] as String?) ??
            user.displayName ??
            user.email ??
            user.uid;

        await FirebaseFirestore.instance.collection('timeClockRecords').add({
          'userId': user.uid,
          'userName': userName,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'OUT',
          'isManualEntry': false,
          'device': 'Windows (auto-cierre)',
        });
        debugPrint(
          '🛡️ SessionShield: Fichaje de salida automático por inactividad.',
        );
      }
    } catch (e) {
      debugPrint('🛡️ SessionShield: Error al fichar salida: $e');
    }

    await FirebaseAuth.instance.signOut();
    debugPrint('🛡️ SessionShield: Sesión cerrada por inactividad.');
  }
}
