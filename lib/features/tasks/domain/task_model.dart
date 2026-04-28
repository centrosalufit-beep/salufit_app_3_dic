import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

enum TaskEstado {
  @JsonValue('pendiente')
  pendiente,
  @JsonValue('en_progreso')
  enProgreso,
  @JsonValue('finalizada')
  finalizada,
}

extension TaskEstadoX on TaskEstado {
  String get label {
    switch (this) {
      case TaskEstado.pendiente:
        return 'Pendiente';
      case TaskEstado.enProgreso:
        return 'En progreso';
      case TaskEstado.finalizada:
        return 'Finalizada';
    }
  }

  String get firestoreValue {
    switch (this) {
      case TaskEstado.pendiente:
        return 'pendiente';
      case TaskEstado.enProgreso:
        return 'en_progreso';
      case TaskEstado.finalizada:
        return 'finalizada';
    }
  }

  static TaskEstado fromFirestore(String? raw) {
    switch (raw) {
      case 'en_progreso':
        return TaskEstado.enProgreso;
      case 'finalizada':
        return TaskEstado.finalizada;
      case 'pendiente':
      default:
        return TaskEstado.pendiente;
    }
  }
}

@freezed
abstract class TaskModel with _$TaskModel {
  const factory TaskModel({
    required String id,
    required String titulo,
    required DateTime fechaLimite,
    required String asignadorUid,
    required String asignadorNombre,
    required String asignadoUid,
    required String asignadoNombre,
    required DateTime fechaCreacion,
    @Default('') String descripcion,
    @Default(TaskEstado.pendiente) TaskEstado estado,
    DateTime? fechaActualizacion,
    DateTime? fechaCompletada,
    @Default('') String grupoAsignacion,
  }) = _TaskModel;

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  factory TaskModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return TaskModel(
      id: doc.id,
      titulo: (d['titulo'] as String?) ?? '',
      descripcion: (d['descripcion'] as String?) ?? '',
      fechaLimite:
          (d['fechaLimite'] as Timestamp?)?.toDate() ?? DateTime.now(),
      asignadorUid: (d['asignadorUid'] as String?) ?? '',
      asignadorNombre: (d['asignadorNombre'] as String?) ?? '',
      asignadoUid: (d['asignadoUid'] as String?) ?? '',
      asignadoNombre: (d['asignadoNombre'] as String?) ?? '',
      estado: TaskEstadoX.fromFirestore(d['estado'] as String?),
      fechaCreacion:
          (d['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaActualizacion:
          (d['fechaActualizacion'] as Timestamp?)?.toDate(),
      fechaCompletada: (d['fechaCompletada'] as Timestamp?)?.toDate(),
      grupoAsignacion: (d['grupoAsignacion'] as String?) ?? '',
    );
  }
}
