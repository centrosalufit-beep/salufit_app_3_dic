// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  uid: json['uid'] as String,
  email: json['email'] as String,
  nombre: json['nombre'] as String? ?? '',
  nombreCompleto: json['nombreCompleto'] as String? ?? '',
  numeroHistoria: json['numeroHistoria'] as String? ?? '',
  role: json['role'] as String? ?? 'cliente',
  onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
  tokensRestantes: (json['tokensRestantes'] as num?)?.toInt() ?? 0,
  migrated: json['migrated'] as bool? ?? false,
  termsAccepted: json['termsAccepted'] as bool? ?? false,
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'nombre': instance.nombre,
      'nombreCompleto': instance.nombreCompleto,
      'numeroHistoria': instance.numeroHistoria,
      'role': instance.role,
      'onboardingCompleted': instance.onboardingCompleted,
      'tokensRestantes': instance.tokensRestantes,
      'migrated': instance.migrated,
      'termsAccepted': instance.termsAccepted,
    };
