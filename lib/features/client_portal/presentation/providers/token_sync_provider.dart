import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';

/// Proveedor que sincroniza el saldo real de tokens desde la colección 'passes'
final userActiveTokensProvider = StreamProvider.autoDispose<int>((ref) {
  final userAsync = ref.watch(userProfileProvider);
  final userId = userAsync.value?.id;
  
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
