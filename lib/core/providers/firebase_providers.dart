import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Providers centralizados para todas las dependencias Firebase.
///
/// Usar estos providers en lugar de `FirebaseAuth.instance` o
/// `FirebaseFirestore.instance` directamente permite inyectar mocks en
/// tests (fake_cloud_firestore, firebase_auth_mocks), lo que hace posible
/// testear pantallas de UI sin dependencias reales.
///
/// Uso típico:
/// ```dart
/// class MyScreen extends ConsumerWidget {
///   Widget build(context, ref) {
///     final auth = ref.watch(firebaseAuthProvider);
///     final db = ref.watch(firebaseFirestoreProvider);
///     ...
///   }
/// }
/// ```
///
/// En tests:
/// ```dart
/// ProviderScope(
///   overrides: [
///     firebaseAuthProvider.overrideWithValue(MockFirebaseAuth(...)),
///     firebaseFirestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
///   ],
///   child: ...
/// )
/// ```
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instance;
});

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});
