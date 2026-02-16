import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> signIn({required String email, required String password}) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) throw AuthException('Error al obtener usuario.');

      await _checkAndClaimLegacyData(user);
    } on FirebaseAuthException {} on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } on FirebaseException catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Error de conexión: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.setLanguageCode('es');
      final actionCodeSettings = ActionCodeSettings(url: 'https://salufitnewapp.firebaseapp.com', handleCodeInApp: true, androidPackageName: 'com.salufit.app', iOSBundleId: 'com.salufit.app');
      await _auth.sendPasswordResetEmail(email: email, actionCodeSettings: actionCodeSettings);
    } on FirebaseAuthException {} on FirebaseException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  Future<void> _checkAndClaimLegacyData(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    
    final legacyQuery = await _firestore
        .collection('legacy_import')
        .where('email', isEqualTo: user.email)
        .get();

    if (legacyQuery.docs.isEmpty) return;

    final legacyDoc = legacyQuery.docs.first;
    final legacyData = legacyDoc.data();

    if (legacyData.safeBool('migrated')) return;

    await userRef.set(
      {
        ...legacyData,
        'uid': user.uid,
        'id': user.uid,
        'migrated': true,
        'termsAccepted': false,
        'privacyAccepted': false,
        'migratedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await legacyDoc.reference.update({'migrated': true, 'migratedTo': user.uid});
    dev.log('>>> [MIGRACIÓN] Datos legacy movidos exitosamente al UID: ${user.uid}');
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('No hay usuario autenticado');
    try {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    } on FirebaseAuthException {} on FirebaseException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException('requires-recent-login');
      }
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuario no registrado.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'too-many-requests':
        return 'Cuenta bloqueada temporalmente.';
      default:
        return 'Error de acceso ($code)';
    }
  }

  Future<void> signOut() => _auth.signOut();
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
