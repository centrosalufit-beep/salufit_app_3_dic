// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whatsapp_conversation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WhatsAppMessage _$WhatsAppMessageFromJson(Map<String, dynamic> json) =>
    _WhatsAppMessage(
      rol: json['rol'] as String? ?? '',
      texto: json['texto'] as String? ?? '',
      timestamp: const TimestampConverter().fromJson(json['timestamp']),
    );

Map<String, dynamic> _$WhatsAppMessageToJson(_WhatsAppMessage instance) =>
    <String, dynamic>{
      'rol': instance.rol,
      'texto': instance.texto,
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
    };

_WhatsAppConversation _$WhatsAppConversationFromJson(
  Map<String, dynamic> json,
) => _WhatsAppConversation(
  id: json['id'] as String,
  pacienteNombre: json['pacienteNombre'] as String? ?? '',
  pacienteTelefono: json['pacienteTelefono'] as String? ?? '',
  appointmentId: json['appointmentId'] as String?,
  tipo: json['tipo'] as String? ?? 'paciente_iniciado',
  estado: json['estado'] as String? ?? 'activa',
  intencionDetectada: json['intencionDetectada'] as String?,
  resultado: json['resultado'] as String?,
  mensajes:
      (json['mensajes'] as List<dynamic>?)
          ?.map((e) => WhatsAppMessage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <WhatsAppMessage>[],
  fechaCreacion: const TimestampConverter().fromJson(json['fechaCreacion']),
  fechaUltimaInteraccion: const TimestampConverter().fromJson(
    json['fechaUltimaInteraccion'],
  ),
  gestionadoPor: json['gestionadoPor'] as String? ?? 'bot',
  profesional: json['profesional'] as String? ?? '',
  fechaCita: const TimestampConverter().fromJson(json['fechaCita']),
);

Map<String, dynamic> _$WhatsAppConversationToJson(
  _WhatsAppConversation instance,
) => <String, dynamic>{
  'id': instance.id,
  'pacienteNombre': instance.pacienteNombre,
  'pacienteTelefono': instance.pacienteTelefono,
  'appointmentId': instance.appointmentId,
  'tipo': instance.tipo,
  'estado': instance.estado,
  'intencionDetectada': instance.intencionDetectada,
  'resultado': instance.resultado,
  'mensajes': instance.mensajes,
  'fechaCreacion': const TimestampConverter().toJson(instance.fechaCreacion),
  'fechaUltimaInteraccion': const TimestampConverter().toJson(
    instance.fechaUltimaInteraccion,
  ),
  'gestionadoPor': instance.gestionadoPor,
  'profesional': instance.profesional,
  'fechaCita': const TimestampConverter().toJson(instance.fechaCita),
};
