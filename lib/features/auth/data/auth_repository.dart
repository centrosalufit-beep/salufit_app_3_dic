import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) => AuthRepository();

class AuthRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> acceptTermsWithMetadata(String uid, Map<String, dynamic> metadata) async {
    await _db.collection('users_app').doc(uid).update({
      ...metadata,
      'termsAccepted': true,
      'termsAcceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('audit_logs').add({
      'tipo': 'ACEPTACIÓN_LEGAL',
      'userId': uid,
      'fecha': FieldValue.serverTimestamp(),
      'metadata': metadata,
    });
  }

  Future<void> acceptTerms(String uid) async {
    await _db.collection('users_app').doc(uid).update({
      'termsAccepted': true,
      'termsAcceptedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // FIRMA REQUERIDA POR ACTIVATION_PROVIDER
  Future<void> sendOTP(String email) async {
    await Future<void>.delayed(const Duration(seconds: 1)); 
  }

  // FIRMA CORREGIDA: Coincidiendo con los errores detectados (userId y code)
  Future<void> activateAccount({
    required String userId, 
    required String code, 
    String? password,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}
