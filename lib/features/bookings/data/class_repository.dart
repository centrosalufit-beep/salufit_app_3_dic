import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final classRepositoryProvider =
    Provider<ClassRepository>((ref) => ClassRepository());

class ClassRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> inscribirUsuario({
    required String userId,
    required String userEmail,
    required String classId,
  }) async {
    final batch = _firestore.batch();

    // Buscar bono activo
    final passSnapshot = await _firestore
        .collection('passes')
        .where('userId', isEqualTo: userId)
        .where('activo', isEqualTo: true)
        .limit(1)
        .get();

    if (passSnapshot.docs.isEmpty) throw Exception('No tienes un bono activo');

    final userRef = _firestore.collection('users_app').doc(userId);
    final userDoc = await userRef.get();
    final userName = userDoc.data()?['nombreCompleto'] ?? 'Usuario';

    batch
      ..set(_firestore.collection('bookings').doc(), {
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'groupClassId': classId,
        'fechaReserva': FieldValue.serverTimestamp(),
        'estado': 'confirmado',
      })
      ..update(
        _firestore.collection('groupClasses').doc(classId),
        {'aforoActual': FieldValue.increment(1)},
      )
      ..update(
        passSnapshot.docs.first.reference,
        {'tokensRestantes': FieldValue.increment(-1)},
      );

    await batch.commit();
  }

  Future<bool> cancelarReserva({
    required String bookingId,
    required String classId,
    required String userId,
  }) async {
    final batch = _firestore.batch();

    // Obtener fecha de la clase para verificar politica 24h
    final classDoc = await _firestore.collection('groupClasses').doc(classId).get();
    final classData = classDoc.data();
    final fechaClase = (classData?['fechaHoraInicio'] as Timestamp?)?.toDate() ?? DateTime.now();
    final horasRestantes = fechaClase.difference(DateTime.now()).inHours;
    final devuelveToken = horasRestantes >= 24;

    batch
      ..delete(_firestore.collection('bookings').doc(bookingId))
      ..update(
        _firestore.collection('groupClasses').doc(classId),
        {'aforoActual': FieldValue.increment(-1)},
      );

    // Solo devolver token si faltan 24h o mas
    if (devuelveToken) {
      final passSnapshot = await _firestore
          .collection('passes')
          .where('userId', isEqualTo: userId)
          .where('activo', isEqualTo: true)
          .limit(1)
          .get();

      if (passSnapshot.docs.isNotEmpty) {
        batch.update(
          passSnapshot.docs.first.reference,
          {'tokensRestantes': FieldValue.increment(1)},
        );
      }
    }

    await batch.commit();
    return devuelveToken;
  }

  Future<void> crearClase({
    required String nombre,
    required String monitor,
    required DateTime fechaHoraInicio,
    required int aforoMaximo,
  }) async {
    await _firestore.collection('groupClasses').add({
      'nombre': nombre,
      'monitor': monitor,
      'fechaHoraInicio': Timestamp.fromDate(fechaHoraInicio),
      'aforoMaximo': aforoMaximo,
      'aforoActual': 0,
      'estado': 'activa',
      'fechaCreacion': FieldValue.serverTimestamp(),
    });
  }
}
