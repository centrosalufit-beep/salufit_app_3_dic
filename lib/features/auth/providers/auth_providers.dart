// lib/features/auth/providers/auth_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/features/auth/services/auth_service.dart';

// 0. Proveedor del Servicio de Autenticación
final Provider<AuthService> authServiceProvider =
    Provider<AuthService>((Ref ref) {
  return AuthService();
});

// 1. Usuario Autenticado (Firebase Auth)
final StreamProvider<User?> authUserProvider = StreamProvider<User?>((Ref ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 2. Email actual
final Provider<String?> currentUserEmailProvider = Provider<String?>((Ref ref) {
  return ref.watch(authUserProvider).value?.email;
});

// 3. ID actual
final Provider<String?> currentUserIdProvider = Provider<String?>((Ref ref) {
  return ref.watch(authUserProvider).value?.uid;
});

// 4. Perfil de Usuario (Firestore) - TIPO ESTRICTO
// Corrección: Forzamos el tipo Map<String, dynamic> para evitar errores de cast en la UI
final StreamProvider<DocumentSnapshot<Map<String, dynamic>>>
    userProfileProvider =
    StreamProvider<DocumentSnapshot<Map<String, dynamic>>>((Ref ref) {
  final uid = ref.watch(currentUserIdProvider);

  if (uid == null) {
    return const Stream.empty();
  }

  // Usamos withConverter para garantizar que Dart entienda los datos como Mapa
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .withConverter<Map<String, dynamic>>(
        fromFirestore: (snapshot, _) => snapshot.data() ?? {},
        toFirestore: (data, _) => data,
      )
      .snapshots();
});
