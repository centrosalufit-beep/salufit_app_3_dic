import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'clinni_appointment_model.freezed.dart';
part 'clinni_appointment_model.g.dart';

@freezed
abstract class ClinniAppointment with _$ClinniAppointment {
  const factory ClinniAppointment({
    required String id,
    required String pacienteNombre,
    required String pacienteTelefono,
    @TimestampConverter() required DateTime fechaCita,
    required String profesional,
    @Default('') String servicio,
    @Default('pendiente') String estado,
    @Default(false) bool recordatorioEnviado,
    @TimestampConverter() DateTime? fechaRecordatorio,
    @Default('') String deduplicationKey,
    @TimestampConverter() DateTime? importadoEn,
    @Default('') String origenExcel,
    @Default('') String notas,
  }) = _ClinniAppointment;

  factory ClinniAppointment.fromJson(Map<String, dynamic> json) =>
      _$ClinniAppointmentFromJson(json);

  factory ClinniAppointment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = {...?doc.data(), 'id': doc.id};
    return ClinniAppointment.fromJson(data);
  }
}

class TimestampConverter implements JsonConverter<DateTime?, Object?> {
  const TimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is DateTime) return json;
    if (json is String) return DateTime.tryParse(json);
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    return null;
  }

  @override
  Object? toJson(DateTime? value) =>
      value == null ? null : Timestamp.fromDate(value);
}
