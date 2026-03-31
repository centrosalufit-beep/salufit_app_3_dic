import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:salufit_app/features/auth/domain/user_model.dart';
import 'package:salufit_app/features/auth/providers/auth_provider.dart';

part 'user_profile_provider.g.dart';

@riverpod
Stream<UserModel?> userProfile(Ref ref) {
  final authAsync = ref.watch(authStateProvider);
  
  return authAsync.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      
      return FirebaseFirestore.instance
          .collection('users_app')
          .doc(user.uid)
          .snapshots()
          .map((doc) {
            if (!doc.exists || doc.data() == null) return null;
            
            final data = doc.data()!;
            // Limpieza preventiva de datos antes de pasar al modelo
            return UserModel.fromJson({
              ...data,
              'uid': doc.id,
              'email': data['email'] ?? user.email ?? '',
            });
          });
    },
    error: Stream.error,
    loading: () => const Stream.empty(),
  );
}
