import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';

final classesStreamProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  final now = DateTime.now();
  return FirebaseFirestore.instance
      .collection('groupClasses')
      .where(
        'fechaHoraInicio',
        isGreaterThanOrEqualTo:
            Timestamp.fromDate(now.subtract(const Duration(minutes: 15))),
      )
      .orderBy('fechaHoraInicio')
      .snapshots();
});

final myBookingsStreamProvider =
    StreamProvider.autoDispose<QuerySnapshot>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('bookings')
      .where('userId', isEqualTo: userId)
      .snapshots();
});

final myBookingsMapProvider = Provider.autoDispose<Map<String, String>>((ref) {
  final bookingsAsync = ref.watch(myBookingsStreamProvider);
  return bookingsAsync.when(
    data: (snap) {
      final map = <String, String>{};
      for (final doc in snap.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        final cId = data.safeString('groupClassId');
        if (cId.isNotEmpty) map[cId] = doc.id;
      }
      return map;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});
