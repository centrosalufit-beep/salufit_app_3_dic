import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';

final currentUserIdProvider =
    Provider<String?>((ref) => FirebaseAuth.instance.currentUser?.uid);
final currentUserEmailProvider =
    Provider<String?>((ref) => FirebaseAuth.instance.currentUser?.email);

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
