import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'patient_model.freezed.dart';
part 'patient_model.g.dart';

@freezed
abstract class Patient with _$Patient {
  const factory Patient({
    @JsonKey(name: 'legacy_id') required String id,
    required String email,
    @Default('') String firstName,
    @Default('') String lastName,
    @Default('') String fullName,
    @Default('') String phoneNumber,
    @Default('') String dni,
    @Default(0) int tokens,
    @Default(false) bool migrated,
  }) = _Patient;

  factory Patient.fromJson(Map<String, dynamic> json) => _$PatientFromJson(json);
}

extension PatientFirestoreX on DocumentSnapshot<Map<String, dynamic>> {
  Patient toPatient() {
    final data = this.data() ?? <String, dynamic>{};
    final fixedData = Map<String, dynamic>.from(data);
    
    if (fixedData['legacy_id'] == null) {
      fixedData['legacy_id'] = id;
    }
    if (fixedData['email'] == null) {
      fixedData['email'] = '';
    }
    
    return Patient.fromJson(fixedData);
  }
}
