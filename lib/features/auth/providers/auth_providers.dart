import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:salufit_app/features/auth/services/auth_service.dart';

part 'auth_providers.g.dart';

@riverpod
AuthService authService(Ref ref) => AuthService();

@riverpod
Stream<User?> authUser(Ref ref) => FirebaseAuth.instance.authStateChanges();

@riverpod
String? currentUserId(Ref ref) => ref.watch(authUserProvider).value?.uid;

@riverpod
String? currentUserEmail(Ref ref) => ref.watch(authUserProvider).value?.email;
