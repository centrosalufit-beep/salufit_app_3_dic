import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:salufit_app/features/whatsapp_bot/domain/clinni_appointment_model.dart' show TimestampConverter;

part 'whatsapp_conversation_model.freezed.dart';
part 'whatsapp_conversation_model.g.dart';

@freezed
abstract class WhatsAppMessage with _$WhatsAppMessage {
  const factory WhatsAppMessage({
    @Default('') String rol, // "paciente" | "bot"
    @Default('') String texto,
    @TimestampConverter() DateTime? timestamp,
  }) = _WhatsAppMessage;

  factory WhatsAppMessage.fromJson(Map<String, dynamic> json) =>
      _$WhatsAppMessageFromJson(json);
}

@freezed
abstract class WhatsAppConversation with _$WhatsAppConversation {
  const factory WhatsAppConversation({
    required String id,
    @Default('') String pacienteNombre,
    @Default('') String pacienteTelefono,
    String? appointmentId,
    @Default('paciente_iniciado') String tipo, // recordatorio | paciente_iniciado
    @Default('activa') String estado,
    String? intencionDetectada,
    String? resultado,
    @Default(<WhatsAppMessage>[]) List<WhatsAppMessage> mensajes,
    @TimestampConverter() DateTime? fechaCreacion,
    @TimestampConverter() DateTime? fechaUltimaInteraccion,
    @Default('bot') String gestionadoPor,
    @Default('') String profesional,
    @TimestampConverter() DateTime? fechaCita,
  }) = _WhatsAppConversation;

  factory WhatsAppConversation.fromJson(Map<String, dynamic> json) =>
      _$WhatsAppConversationFromJson(json);

  factory WhatsAppConversation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final raw = {...?doc.data(), 'id': doc.id};
    // mensajes puede venir como List<Map<String, dynamic>> directamente
    return WhatsAppConversation.fromJson(raw);
  }
}
