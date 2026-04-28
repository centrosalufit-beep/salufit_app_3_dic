import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salufit_app/features/tasks/domain/task_model.dart';

class TaskRepository {
  TaskRepository(this._db);
  final FirebaseFirestore _db;

  static const String _collection = 'tasks';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _db.collection(_collection);

  Stream<List<TaskModel>> watchReceivedTasks({
    required String uid,
    required bool includeArchived,
  }) {
    var query = _ref.where('asignadoUid', isEqualTo: uid);
    if (!includeArchived) {
      query = query.where('estado', whereIn: ['pendiente', 'en_progreso']);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map(TaskModel.fromFirestore).toList()
            ..sort(_sortTasks),
        );
  }

  Stream<List<TaskModel>> watchAssignedTasks({
    required String uid,
    required bool includeArchived,
  }) {
    var query = _ref.where('asignadorUid', isEqualTo: uid);
    if (!includeArchived) {
      query = query.where('estado', whereIn: ['pendiente', 'en_progreso']);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map(TaskModel.fromFirestore).toList()
            ..sort(_sortTasks),
        );
  }

  Stream<int> watchPendingCount(String uid) {
    return _ref
        .where('asignadoUid', isEqualTo: uid)
        .where('estado', whereIn: ['pendiente', 'en_progreso'])
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> createTasks({
    required String titulo,
    required String descripcion,
    required DateTime fechaLimite,
    required String asignadorUid,
    required String asignadorNombre,
    required List<({String uid, String nombre})> destinatarios,
  }) async {
    if (destinatarios.isEmpty) return;
    final batch = _db.batch();
    final grupo = _db.collection(_collection).doc().id;
    final now = FieldValue.serverTimestamp();
    final fechaLimiteNormalizada = DateTime(
      fechaLimite.year,
      fechaLimite.month,
      fechaLimite.day,
      23,
      59,
      59,
    );

    for (final dest in destinatarios) {
      final docRef = _ref.doc();
      batch.set(docRef, {
        'titulo': titulo.trim(),
        'descripcion': descripcion.trim(),
        'fechaLimite': Timestamp.fromDate(fechaLimiteNormalizada),
        'asignadorUid': asignadorUid,
        'asignadorNombre': asignadorNombre,
        'asignadoUid': dest.uid,
        'asignadoNombre': dest.nombre,
        'estado': TaskEstado.pendiente.firestoreValue,
        'fechaCreacion': now,
        'grupoAsignacion': destinatarios.length > 1 ? grupo : '',
      });
    }

    await batch.commit();
  }

  Future<void> updateEstado({
    required String taskId,
    required TaskEstado nuevoEstado,
  }) async {
    final payload = <String, dynamic>{
      'estado': nuevoEstado.firestoreValue,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    };
    if (nuevoEstado == TaskEstado.finalizada) {
      payload['fechaCompletada'] = FieldValue.serverTimestamp();
    }
    await _ref.doc(taskId).update(payload);
  }

  Future<void> deleteTask(String taskId) async {
    await _ref.doc(taskId).delete();
  }

  int _sortTasks(TaskModel a, TaskModel b) {
    final orderA = a.estado == TaskEstado.finalizada ? 1 : 0;
    final orderB = b.estado == TaskEstado.finalizada ? 1 : 0;
    if (orderA != orderB) return orderA.compareTo(orderB);
    return a.fechaLimite.compareTo(b.fechaLimite);
  }
}
