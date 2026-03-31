import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String email,
    @Default('') String nombre,         // Tolerante a null (devuelve vacío)
    @Default('') String nombreCompleto, // Tolerante a null
    @Default('') String numeroHistoria, // Tolerante a null
    @Default('cliente') String role,
    @Default(false) bool onboardingCompleted,
    @Default(0) int tokensRestantes,
    @Default(false) bool migrated,
    @Default(false) bool termsAccepted,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);
}
