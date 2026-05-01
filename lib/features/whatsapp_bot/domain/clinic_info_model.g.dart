// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinic_info_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DayHours _$DayHoursFromJson(Map<String, dynamic> json) => _DayHours(
  abre: json['abre'] as String? ?? '09:00',
  cierra: json['cierra'] as String? ?? '20:00',
);

Map<String, dynamic> _$DayHoursToJson(_DayHours instance) => <String, dynamic>{
  'abre': instance.abre,
  'cierra': instance.cierra,
};

_ServicioInfo _$ServicioInfoFromJson(Map<String, dynamic> json) =>
    _ServicioInfo(
      nombre: json['nombre'] as String? ?? '',
      precio: (json['precio'] as num?)?.toInt(),
      descripcion: json['descripcion'] as String?,
    );

Map<String, dynamic> _$ServicioInfoToJson(_ServicioInfo instance) =>
    <String, dynamic>{
      'nombre': instance.nombre,
      'precio': instance.precio,
      'descripcion': instance.descripcion,
    };

_ClinicInfo _$ClinicInfoFromJson(Map<String, dynamic> json) => _ClinicInfo(
  horarios:
      (json['horarios'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          e == null ? null : DayHours.fromJson(e as Map<String, dynamic>),
        ),
      ) ??
      const <String, DayHours?>{},
  direccion: json['direccion'] as String? ?? '',
  googleMapsUrl: json['googleMapsUrl'] as String? ?? '',
  telefonoRecepcion: json['telefonoRecepcion'] as String? ?? '',
  parking: json['parking'] as String? ?? '',
  comoLlegar: json['comoLlegar'] as String? ?? '',
  primeraVisita: json['primeraVisita'] as String? ?? '',
  servicios:
      (json['servicios'] as List<dynamic>?)
          ?.map((e) => ServicioInfo.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ServicioInfo>[],
  bienvenidaNuevoPaciente: json['bienvenidaNuevoPaciente'] as String? ?? '',
);

Map<String, dynamic> _$ClinicInfoToJson(_ClinicInfo instance) =>
    <String, dynamic>{
      'horarios': instance.horarios,
      'direccion': instance.direccion,
      'googleMapsUrl': instance.googleMapsUrl,
      'telefonoRecepcion': instance.telefonoRecepcion,
      'parking': instance.parking,
      'comoLlegar': instance.comoLlegar,
      'primeraVisita': instance.primeraVisita,
      'servicios': instance.servicios,
      'bienvenidaNuevoPaciente': instance.bienvenidaNuevoPaciente,
    };

_ClinicHoliday _$ClinicHolidayFromJson(Map<String, dynamic> json) =>
    _ClinicHoliday(
      fecha: json['fecha'] as String? ?? '',
      motivo: json['motivo'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'festivo',
      horarioEspecial: json['horarioEspecial'] == null
          ? null
          : DayHours.fromJson(json['horarioEspecial'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ClinicHolidayToJson(_ClinicHoliday instance) =>
    <String, dynamic>{
      'fecha': instance.fecha,
      'motivo': instance.motivo,
      'tipo': instance.tipo,
      'horarioEspecial': instance.horarioEspecial,
    };
