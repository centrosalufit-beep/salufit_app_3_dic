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
      final allRecords = await FirebaseFirestore.instance
          .collection('timeClockRecords')
          .where('userId', isEqualTo: user.uid)
          .limit(20)
          .get();
      // Ordenar en código
      final sorted = allRecords.docs.toList()
        ..sort((a, b) {
          final tsA = (a.data()['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final tsB = (b.data()['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return tsB.compareTo(tsA);
        });

      if (sorted.isNotEmpty && sorted.first.get('type') == 'IN') {
        final lastData = sorted.first.data();
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
