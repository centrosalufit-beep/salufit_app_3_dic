import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'clinic_info_model.freezed.dart';
part 'clinic_info_model.g.dart';

/// Horario de un día concreto. `null` representa cerrado.
@freezed
abstract class DayHours with _$DayHours {
  const factory DayHours({
    @Default('09:00') String abre,
    @Default('20:00') String cierra,
  }) = _DayHours;

  factory DayHours.fromJson(Map<String, dynamic> json) =>
      _$DayHoursFromJson(json);
}

@freezed
abstract class ServicioInfo with _$ServicioInfo {
  const factory ServicioInfo({
    @Default('') String nombre,
    int? precio,
    String? descripcion,
  }) = _ServicioInfo;

  factory ServicioInfo.fromJson(Map<String, dynamic> json) =>
      _$ServicioInfoFromJson(json);
}

@freezed
abstract class ClinicInfo with _$ClinicInfo {
  const factory ClinicInfo({
    @Default(<String, DayHours?>{}) Map<String, DayHours?> horarios,
    @Default('') String direccion,
    @Default('') String googleMapsUrl,
    @Default('') String telefonoRecepcion,
    @Default('') String parking,
    @Default('') String comoLlegar,
    @Default('') String primeraVisita,
    @Default(<ServicioInfo>[]) List<ServicioInfo> servicios,
    @Default('') String bienvenidaNuevoPaciente,
  }) = _ClinicInfo;

  factory ClinicInfo.fromJson(Map<String, dynamic> json) =>
      _$ClinicInfoFromJson(json);

  factory ClinicInfo.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final raw = doc.data() ?? <String, dynamic>{};
    return ClinicInfo.fromJson(raw);
  }
}

/// Festivo editable desde el panel.
@freezed
abstract class ClinicHoliday with _$ClinicHoliday {
  const factory ClinicHoliday({
    @Default('') String fecha, // ISO YYYY-MM-DD (también es el doc ID)
    @Default('') String motivo,
    @Default('festivo') String tipo, // festivo | cerrado_excepcional | horario_reducido
    DayHours? horarioEspecial,
  }) = _ClinicHoliday;

  factory ClinicHoliday.fromJson(Map<String, dynamic> json) =>
      _$ClinicHolidayFromJson(json);

  factory ClinicHoliday.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final raw = {...?doc.data(), 'fecha': doc.data()?['fecha'] ?? doc.id};
    return ClinicHoliday.fromJson(raw);
  }
}

/// Ausencia temporal de un profesional (vacaciones, baja, formación).
@freezed
abstract class ProfessionalAbsence with _$ProfessionalAbsence {
  const factory ProfessionalAbsence({
    @Default('') String id,
    @Default('') String profesionalId,
    @Default('') String profesionalNombre,
    DateTime? desde,
    DateTime? hasta,
    @Default('') String motivo,
  }) = _ProfessionalAbsence;

  factory ProfessionalAbsence.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final raw = doc.data() ?? <String, dynamic>{};
    return ProfessionalAbsence(
      id: doc.id,
      profesionalId: (raw['profesionalId'] as String?) ?? '',
      profesionalNombre: (raw['profesionalNombre'] as String?) ?? '',
      desde: (raw['desde'] as Timestamp?)?.toDate(),
      hasta: (raw['hasta'] as Timestamp?)?.toDate(),
      motivo: (raw['motivo'] as String?) ?? '',
    );
  }
}
