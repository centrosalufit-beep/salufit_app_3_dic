// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinni_appointment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClinniAppointment _$ClinniAppointmentFromJson(Map<String, dynamic> json) =>
    _ClinniAppointment(
      id: json['id'] as String,
      pacienteNombre: json['pacienteNombre'] as String,
      pacienteTelefono: json['pacienteTelefono'] as String,
      fechaCita: DateTime.parse(json['fechaCita'] as String),
      profesional: json['profesional'] as String,
      servicio: json['servicio'] as String? ?? '',
      estado: json['estado'] as String? ?? 'pendiente',
      recordatorioEnviado: json['recordatorioEnviado'] as bool? ?? false,
      fechaRecordatorio: const TimestampConverter().fromJson(
        json['fechaRecordatorio'],
      ),
      deduplicationKey: json['deduplicationKey'] as String? ?? '',
      importadoEn: const TimestampConverter().fromJson(json['importadoEn']),
      origenExcel: json['origenExcel'] as String? ?? '',
      notas: json['notas'] as String? ?? '',
    );

Map<String, dynamic> _$ClinniAppointmentToJson(_ClinniAppointment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pacienteNombre': instance.pacienteNombre,
      'pacienteTelefono': instance.pacienteTelefono,
      'fechaCita': instance.fechaCita.toIso8601String(),
      'profesional': instance.profesional,
      'servicio': instance.servicio,
      'estado': instance.estado,
      'recordatorioEnviado': instance.recordatorioEnviado,
      'fechaRecordatorio': const TimestampConverter().toJson(
        instance.fechaRecordatorio,
      ),
      'deduplicationKey': instance.deduplicationKey,
      'importadoEn': const TimestampConverter().toJson(instance.importadoEn),
      'origenExcel': instance.origenExcel,
      'notas': instance.notas,
    };
