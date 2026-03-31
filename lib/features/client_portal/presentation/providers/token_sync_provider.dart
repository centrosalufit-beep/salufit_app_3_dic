import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:salufit_app/features/auth/providers/user_profile_provider.dart';

part 'token_sync_provider.g.dart';

@riverpod
String? userTokenSync(Ref ref) {
  final userAsync = ref.watch(userProfileProvider);
  // CORRECCIÓN: Usar uid según UserModel
  return userAsync.value?.uid;
}

final userActiveTokensProvider = StreamProvider.autoDispose<int>((ref) {
  final userId = ref.watch(userTokenSyncProvider);
  
  if (userId == null) return Stream<int>.value(0);

  return FirebaseFirestore.instance
      .collection('passes')
      .where('userId', isEqualTo: userId)
      .where('activo', isEqualTo: true)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return 0;
    final data = snapshot.docs.first.data();
    return (data['tokensRestantes'] as num?)?.toInt() ?? 0;
  });
});
