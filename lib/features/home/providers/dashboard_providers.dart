// lib/features/home/providers/dashboard_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salufit_app/core/utils/safe_parsing_extensions.dart';
import 'package:salufit_app/features/auth/providers/auth_providers.dart';

// 1. Proveedor de Reservas Activas (Saneado)
final myActiveBookingsProvider =
    StreamProvider.autoDispose<List<QueryDocumentSnapshot>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();

  // Sin orderBy para evitar índice compuesto — ordenamos en código
  return FirebaseFirestore.instance
      .collection('bookings')
      .where('userId', isEqualTo: userId)
      .limit(20)
      .snapshots()
      .map((snapshot) {
    final docs = snapshot.docs.toList()
      ..sort((a, b) {
        final tsA = ((a.data()['fechaReserva'] as Timestamp?)
                    ?.toDate() ??
                DateTime(1970))
            .millisecondsSinceEpoch;
        final tsB = ((b.data()['fechaReserva'] as Timestamp?)
                    ?.toDate() ??
                DateTime(1970))
            .millisecondsSinceEpoch;
        return tsB.compareTo(tsA);
      });
    return docs.take(5).toList();
  });
});

// 2. Proveedor de "Próxima Clase" (Tipado y Null-Safe)
final nextClassProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final bookingsAsync = await ref.watch(myActiveBookingsProvider.future);

  if (bookingsAsync.isEmpty) return null;

  final now = DateTime.now();
  final candidates = <Map<String, dynamic>>[];

  // Recopilamos IDs con tipos explícitos para evitar errores de dynamic
  final classIds = bookingsAsync
      .map((QueryDocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return data.safeString('groupClassId');
      })
      .where((String id) => id.isNotEmpty)
      .toList();

  if (classIds.isEmpty) return null;

  final classesSnapshot = await FirebaseFirestore.instance
      .collection('groupClasses')
      .where(FieldPath.documentId, whereIn: classIds.take(10).toList())
      .get();

  for (final doc in classesSnapshot.docs) {
    final data = doc.data();
    final fecha = data.safeDateTime('fechaHoraInicio');

    if (fecha.isAfter(now)) {
      candidates.add({
        'nombre': data.safeString('nombre', defaultValue: 'Clase'),
        'fecha': fecha,
        'monitor': data.safeString('monitor'),
        'id': doc.id,
      });
    }
  }

  if (candidates.isEmpty) return null;

  candidates.sort(
    (a, b) => (a['fecha'] as DateTime).compareTo(b['fecha'] as DateTime),
  );
  return candidates.first;
});

// 3. Proveedor de Citas Médicas (CORREGIDO: Orden ASC para la próxima)
final nextAppointmentProvider =
    StreamProvider.autoDispose<DocumentSnapshot?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();

  // Sin orderBy para evitar índice compuesto
  return FirebaseFirestore.instance
      .collection('appointments')
      .where('userId', isEqualTo: userId)
      .limit(10)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return null;
    final sorted = snapshot.docs.toList()
      ..sort((a, b) {
        final tsA = ((a.data()['fechaHoraInicio'] as Timestamp?)
                    ?.toDate() ??
                DateTime(2099))
            .millisecondsSinceEpoch;
        final tsB = ((b.data()['fechaHoraInicio'] as Timestamp?)
                    ?.toDate() ??
                DateTime(2099))
            .millisecondsSinceEpoch;
        return tsA.compareTo(tsB);
      });
    return sorted.first;
  });
});
