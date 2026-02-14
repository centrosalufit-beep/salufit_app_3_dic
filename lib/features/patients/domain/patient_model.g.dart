// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Patient _$PatientFromJson(Map<String, dynamic> json) => _Patient(
      id: json['legacy_id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      dni: json['dni'] as String? ?? '',
      tokens: (json['tokens'] as num?)?.toInt() ?? 0,
      migrated: json['migrated'] as bool? ?? false,
    );

Map<String, dynamic> _$PatientToJson(_Patient instance) => <String, dynamic>{
      'legacy_id': instance.id,
      'email': instance.email,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'fullName': instance.fullName,
      'phoneNumber': instance.phoneNumber,
      'dni': instance.dni,
      'tokens': instance.tokens,
      'migrated': instance.migrated,
    };
