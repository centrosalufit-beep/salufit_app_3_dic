// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => _TaskModel(
  id: json['id'] as String,
  titulo: json['titulo'] as String,
  fechaLimite: DateTime.parse(json['fechaLimite'] as String),
  asignadorUid: json['asignadorUid'] as String,
  asignadorNombre: json['asignadorNombre'] as String,
  asignadoUid: json['asignadoUid'] as String,
  asignadoNombre: json['asignadoNombre'] as String,
  fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
  descripcion: json['descripcion'] as String? ?? '',
  estado:
      $enumDecodeNullable(_$TaskEstadoEnumMap, json['estado']) ??
      TaskEstado.pendiente,
  fechaActualizacion: json['fechaActualizacion'] == null
      ? null
      : DateTime.parse(json['fechaActualizacion'] as String),
  fechaCompletada: json['fechaCompletada'] == null
      ? null
      : DateTime.parse(json['fechaCompletada'] as String),
  grupoAsignacion: json['grupoAsignacion'] as String? ?? '',
);

Map<String, dynamic> _$TaskModelToJson(_TaskModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titulo': instance.titulo,
      'fechaLimite': instance.fechaLimite.toIso8601String(),
      'asignadorUid': instance.asignadorUid,
      'asignadorNombre': instance.asignadorNombre,
      'asignadoUid': instance.asignadoUid,
      'asignadoNombre': instance.asignadoNombre,
      'fechaCreacion': instance.fechaCreacion.toIso8601String(),
      'descripcion': instance.descripcion,
      'estado': _$TaskEstadoEnumMap[instance.estado]!,
      'fechaActualizacion': instance.fechaActualizacion?.toIso8601String(),
      'fechaCompletada': instance.fechaCompletada?.toIso8601String(),
      'grupoAsignacion': instance.grupoAsignacion,
    };

const _$TaskEstadoEnumMap = {
  TaskEstado.pendiente: 'pendiente',
  TaskEstado.enProgreso: 'en_progreso',
  TaskEstado.finalizada: 'finalizada',
};
