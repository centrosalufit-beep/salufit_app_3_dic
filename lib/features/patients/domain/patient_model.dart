// lib/features/patients/domain/patient_model.dart
// ignore_for_file: invalid_annotation_target

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'patient_model.freezed.dart';
part 'patient_model.g.dart';

@freezed
class Patient with _$Patient {
  // Configuración JSON estricta
  @JsonSerializable(explicitToJson: true, includeIfNull: false)
  const factory Patient({
    // ID: Obligatorio
    @JsonKey(name: 'legacy_id') required String id,
    required String email,

    // CAMPOS OPCIONALES CON DEFAULT
    @Default('') String firstName,
    @Default('') String lastName,
    @Default('') String fullName,
    @Default('') String phoneNumber,
    @Default('') String dni,
    @Default(0) int tokens,
    @Default(false) bool migrated,
  }) = _Patient;

  factory Patient.fromJson(Map<String, dynamic> json) =>
      _$PatientFromJson(json);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --- EXTENSIÓN DE SEGURIDAD ---
// Esta lógica funciona FUERA de la clase generada.
// Así evitamos conflictos con Freezed y errores de implementación.
extension PatientFirestoreX on DocumentSnapshot {
  Patient toPatient() {
    final data = this.data() as Map<String, dynamic>? ?? {};

    // Parche: Si no tiene legacy_id, usamos el ID del documento
    if (data['legacy_id'] == null || data['legacy_id'] == '') {
      final fixedData = Map<String, dynamic>.from(data);
      fixedData['legacy_id'] = id; // Usamos el ID del documento

      // Evitamos nulos en email
      if (fixedData['email'] == null) fixedData['email'] = '';

      return Patient.fromJson(fixedData);
    }

    return Patient.fromJson(data);
  }
}
