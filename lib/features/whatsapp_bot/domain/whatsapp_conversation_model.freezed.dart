// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'whatsapp_conversation_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WhatsAppMessage {

 String get rol;// "paciente" | "bot"
 String get texto;@TimestampConverter() DateTime? get timestamp;
/// Create a copy of WhatsAppMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WhatsAppMessageCopyWith<WhatsAppMessage> get copyWith => _$WhatsAppMessageCopyWithImpl<WhatsAppMessage>(this as WhatsAppMessage, _$identity);

  /// Serializes this WhatsAppMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WhatsAppMessage&&(identical(other.rol, rol) || other.rol == rol)&&(identical(other.texto, texto) || other.texto == texto)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rol,texto,timestamp);

@override
String toString() {
  return 'WhatsAppMessage(rol: $rol, texto: $texto, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $WhatsAppMessageCopyWith<$Res>  {
  factory $WhatsAppMessageCopyWith(WhatsAppMessage value, $Res Function(WhatsAppMessage) _then) = _$WhatsAppMessageCopyWithImpl;
@useResult
$Res call({
 String rol, String texto,@TimestampConverter() DateTime? timestamp
});




}
/// @nodoc
class _$WhatsAppMessageCopyWithImpl<$Res>
    implements $WhatsAppMessageCopyWith<$Res> {
  _$WhatsAppMessageCopyWithImpl(this._self, this._then);

  final WhatsAppMessage _self;
  final $Res Function(WhatsAppMessage) _then;

/// Create a copy of WhatsAppMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rol = null,Object? texto = null,Object? timestamp = freezed,}) {
  return _then(_self.copyWith(
rol: null == rol ? _self.rol : rol // ignore: cast_nullable_to_non_nullable
as String,texto: null == texto ? _self.texto : texto // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WhatsAppMessage].
extension WhatsAppMessagePatterns on WhatsAppMessage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WhatsAppMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WhatsAppMessage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WhatsAppMessage value)  $default,){
final _that = this;
switch (_that) {
case _WhatsAppMessage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WhatsAppMessage value)?  $default,){
final _that = this;
switch (_that) {
case _WhatsAppMessage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String rol,  String texto, @TimestampConverter()  DateTime? timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WhatsAppMessage() when $default != null:
return $default(_that.rol,_that.texto,_that.timestamp);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String rol,  String texto, @TimestampConverter()  DateTime? timestamp)  $default,) {final _that = this;
switch (_that) {
case _WhatsAppMessage():
return $default(_that.rol,_that.texto,_that.timestamp);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String rol,  String texto, @TimestampConverter()  DateTime? timestamp)?  $default,) {final _that = this;
switch (_that) {
case _WhatsAppMessage() when $default != null:
return $default(_that.rol,_that.texto,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WhatsAppMessage implements WhatsAppMessage {
  const _WhatsAppMessage({this.rol = '', this.texto = '', @TimestampConverter() this.timestamp});
  factory _WhatsAppMessage.fromJson(Map<String, dynamic> json) => _$WhatsAppMessageFromJson(json);

@override@JsonKey() final  String rol;
// "paciente" | "bot"
@override@JsonKey() final  String texto;
@override@TimestampConverter() final  DateTime? timestamp;

/// Create a copy of WhatsAppMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WhatsAppMessageCopyWith<_WhatsAppMessage> get copyWith => __$WhatsAppMessageCopyWithImpl<_WhatsAppMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WhatsAppMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WhatsAppMessage&&(identical(other.rol, rol) || other.rol == rol)&&(identical(other.texto, texto) || other.texto == texto)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rol,texto,timestamp);

@override
String toString() {
  return 'WhatsAppMessage(rol: $rol, texto: $texto, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$WhatsAppMessageCopyWith<$Res> implements $WhatsAppMessageCopyWith<$Res> {
  factory _$WhatsAppMessageCopyWith(_WhatsAppMessage value, $Res Function(_WhatsAppMessage) _then) = __$WhatsAppMessageCopyWithImpl;
@override @useResult
$Res call({
 String rol, String texto,@TimestampConverter() DateTime? timestamp
});




}
/// @nodoc
class __$WhatsAppMessageCopyWithImpl<$Res>
    implements _$WhatsAppMessageCopyWith<$Res> {
  __$WhatsAppMessageCopyWithImpl(this._self, this._then);

  final _WhatsAppMessage _self;
  final $Res Function(_WhatsAppMessage) _then;

/// Create a copy of WhatsAppMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rol = null,Object? texto = null,Object? timestamp = freezed,}) {
  return _then(_WhatsAppMessage(
rol: null == rol ? _self.rol : rol // ignore: cast_nullable_to_non_nullable
as String,texto: null == texto ? _self.texto : texto // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$WhatsAppConversation {

 String get id; String get pacienteNombre; String get pacienteTelefono; String? get appointmentId; String get tipo;// recordatorio | paciente_iniciado
 String get estado; String? get intencionDetectada; String? get resultado; List<WhatsAppMessage> get mensajes;@TimestampConverter() DateTime? get fechaCreacion;@TimestampConverter() DateTime? get fechaUltimaInteraccion; String get gestionadoPor; String get profesional;@TimestampConverter() DateTime? get fechaCita;
/// Create a copy of WhatsAppConversation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WhatsAppConversationCopyWith<WhatsAppConversation> get copyWith => _$WhatsAppConversationCopyWithImpl<WhatsAppConversation>(this as WhatsAppConversation, _$identity);

  /// Serializes this WhatsAppConversation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WhatsAppConversation&&(identical(other.id, id) || other.id == id)&&(identical(other.pacienteNombre, pacienteNombre) || other.pacienteNombre == pacienteNombre)&&(identical(other.pacienteTelefono, pacienteTelefono) || other.pacienteTelefono == pacienteTelefono)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.intencionDetectada, intencionDetectada) || other.intencionDetectada == intencionDetectada)&&(identical(other.resultado, resultado) || other.resultado == resultado)&&const DeepCollectionEquality().equals(other.mensajes, mensajes)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion)&&(identical(other.fechaUltimaInteraccion, fechaUltimaInteraccion) || other.fechaUltimaInteraccion == fechaUltimaInteraccion)&&(identical(other.gestionadoPor, gestionadoPor) || other.gestionadoPor == gestionadoPor)&&(identical(other.profesional, profesional) || other.profesional == profesional)&&(identical(other.fechaCita, fechaCita) || other.fechaCita == fechaCita));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pacienteNombre,pacienteTelefono,appointmentId,tipo,estado,intencionDetectada,resultado,const DeepCollectionEquality().hash(mensajes),fechaCreacion,fechaUltimaInteraccion,gestionadoPor,profesional,fechaCita);

@override
String toString() {
  return 'WhatsAppConversation(id: $id, pacienteNombre: $pacienteNombre, pacienteTelefono: $pacienteTelefono, appointmentId: $appointmentId, tipo: $tipo, estado: $estado, intencionDetectada: $intencionDetectada, resultado: $resultado, mensajes: $mensajes, fechaCreacion: $fechaCreacion, fechaUltimaInteraccion: $fechaUltimaInteraccion, gestionadoPor: $gestionadoPor, profesional: $profesional, fechaCita: $fechaCita)';
}


}

/// @nodoc
abstract mixin class $WhatsAppConversationCopyWith<$Res>  {
  factory $WhatsAppConversationCopyWith(WhatsAppConversation value, $Res Function(WhatsAppConversation) _then) = _$WhatsAppConversationCopyWithImpl;
@useResult
$Res call({
 String id, String pacienteNombre, String pacienteTelefono, String? appointmentId, String tipo, String estado, String? intencionDetectada, String? resultado, List<WhatsAppMessage> mensajes,@TimestampConverter() DateTime? fechaCreacion,@TimestampConverter() DateTime? fechaUltimaInteraccion, String gestionadoPor, String profesional,@TimestampConverter() DateTime? fechaCita
});




}
/// @nodoc
class _$WhatsAppConversationCopyWithImpl<$Res>
    implements $WhatsAppConversationCopyWith<$Res> {
  _$WhatsAppConversationCopyWithImpl(this._self, this._then);

  final WhatsAppConversation _self;
  final $Res Function(WhatsAppConversation) _then;

/// Create a copy of WhatsAppConversation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pacienteNombre = null,Object? pacienteTelefono = null,Object? appointmentId = freezed,Object? tipo = null,Object? estado = null,Object? intencionDetectada = freezed,Object? resultado = freezed,Object? mensajes = null,Object? fechaCreacion = freezed,Object? fechaUltimaInteraccion = freezed,Object? gestionadoPor = null,Object? profesional = null,Object? fechaCita = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pacienteNombre: null == pacienteNombre ? _self.pacienteNombre : pacienteNombre // ignore: cast_nullable_to_non_nullable
as String,pacienteTelefono: null == pacienteTelefono ? _self.pacienteTelefono : pacienteTelefono // ignore: cast_nullable_to_non_nullable
as String,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String,intencionDetectada: freezed == intencionDetectada ? _self.intencionDetectada : intencionDetectada // ignore: cast_nullable_to_non_nullable
as String?,resultado: freezed == resultado ? _self.resultado : resultado // ignore: cast_nullable_to_non_nullable
as String?,mensajes: null == mensajes ? _self.mensajes : mensajes // ignore: cast_nullable_to_non_nullable
as List<WhatsAppMessage>,fechaCreacion: freezed == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaUltimaInteraccion: freezed == fechaUltimaInteraccion ? _self.fechaUltimaInteraccion : fechaUltimaInteraccion // ignore: cast_nullable_to_non_nullable
as DateTime?,gestionadoPor: null == gestionadoPor ? _self.gestionadoPor : gestionadoPor // ignore: cast_nullable_to_non_nullable
as String,profesional: null == profesional ? _self.profesional : profesional // ignore: cast_nullable_to_non_nullable
as String,fechaCita: freezed == fechaCita ? _self.fechaCita : fechaCita // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WhatsAppConversation].
extension WhatsAppConversationPatterns on WhatsAppConversation {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WhatsAppConversation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WhatsAppConversation() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WhatsAppConversation value)  $default,){
final _that = this;
switch (_that) {
case _WhatsAppConversation():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WhatsAppConversation value)?  $default,){
final _that = this;
switch (_that) {
case _WhatsAppConversation() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String pacienteNombre,  String pacienteTelefono,  String? appointmentId,  String tipo,  String estado,  String? intencionDetectada,  String? resultado,  List<WhatsAppMessage> mensajes, @TimestampConverter()  DateTime? fechaCreacion, @TimestampConverter()  DateTime? fechaUltimaInteraccion,  String gestionadoPor,  String profesional, @TimestampConverter()  DateTime? fechaCita)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WhatsAppConversation() when $default != null:
return $default(_that.id,_that.pacienteNombre,_that.pacienteTelefono,_that.appointmentId,_that.tipo,_that.estado,_that.intencionDetectada,_that.resultado,_that.mensajes,_that.fechaCreacion,_that.fechaUltimaInteraccion,_that.gestionadoPor,_that.profesional,_that.fechaCita);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String pacienteNombre,  String pacienteTelefono,  String? appointmentId,  String tipo,  String estado,  String? intencionDetectada,  String? resultado,  List<WhatsAppMessage> mensajes, @TimestampConverter()  DateTime? fechaCreacion, @TimestampConverter()  DateTime? fechaUltimaInteraccion,  String gestionadoPor,  String profesional, @TimestampConverter()  DateTime? fechaCita)  $default,) {final _that = this;
switch (_that) {
case _WhatsAppConversation():
return $default(_that.id,_that.pacienteNombre,_that.pacienteTelefono,_that.appointmentId,_that.tipo,_that.estado,_that.intencionDetectada,_that.resultado,_that.mensajes,_that.fechaCreacion,_that.fechaUltimaInteraccion,_that.gestionadoPor,_that.profesional,_that.fechaCita);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String pacienteNombre,  String pacienteTelefono,  String? appointmentId,  String tipo,  String estado,  String? intencionDetectada,  String? resultado,  List<WhatsAppMessage> mensajes, @TimestampConverter()  DateTime? fechaCreacion, @TimestampConverter()  DateTime? fechaUltimaInteraccion,  String gestionadoPor,  String profesional, @TimestampConverter()  DateTime? fechaCita)?  $default,) {final _that = this;
switch (_that) {
case _WhatsAppConversation() when $default != null:
return $default(_that.id,_that.pacienteNombre,_that.pacienteTelefono,_that.appointmentId,_that.tipo,_that.estado,_that.intencionDetectada,_that.resultado,_that.mensajes,_that.fechaCreacion,_that.fechaUltimaInteraccion,_that.gestionadoPor,_that.profesional,_that.fechaCita);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WhatsAppConversation implements WhatsAppConversation {
  const _WhatsAppConversation({required this.id, this.pacienteNombre = '', this.pacienteTelefono = '', this.appointmentId, this.tipo = 'paciente_iniciado', this.estado = 'activa', this.intencionDetectada, this.resultado, final  List<WhatsAppMessage> mensajes = const <WhatsAppMessage>[], @TimestampConverter() this.fechaCreacion, @TimestampConverter() this.fechaUltimaInteraccion, this.gestionadoPor = 'bot', this.profesional = '', @TimestampConverter() this.fechaCita}): _mensajes = mensajes;
  factory _WhatsAppConversation.fromJson(Map<String, dynamic> json) => _$WhatsAppConversationFromJson(json);

@override final  String id;
@override@JsonKey() final  String pacienteNombre;
@override@JsonKey() final  String pacienteTelefono;
@override final  String? appointmentId;
@override@JsonKey() final  String tipo;
// recordatorio | paciente_iniciado
@override@JsonKey() final  String estado;
@override final  String? intencionDetectada;
@override final  String? resultado;
 final  List<WhatsAppMessage> _mensajes;
@override@JsonKey() List<WhatsAppMessage> get mensajes {
  if (_mensajes is EqualUnmodifiableListView) return _mensajes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mensajes);
}

@override@TimestampConverter() final  DateTime? fechaCreacion;
@override@TimestampConverter() final  DateTime? fechaUltimaInteraccion;
@override@JsonKey() final  String gestionadoPor;
@override@JsonKey() final  String profesional;
@override@TimestampConverter() final  DateTime? fechaCita;

/// Create a copy of WhatsAppConversation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WhatsAppConversationCopyWith<_WhatsAppConversation> get copyWith => __$WhatsAppConversationCopyWithImpl<_WhatsAppConversation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WhatsAppConversationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WhatsAppConversation&&(identical(other.id, id) || other.id == id)&&(identical(other.pacienteNombre, pacienteNombre) || other.pacienteNombre == pacienteNombre)&&(identical(other.pacienteTelefono, pacienteTelefono) || other.pacienteTelefono == pacienteTelefono)&&(identical(other.appointmentId, appointmentId) || other.appointmentId == appointmentId)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.intencionDetectada, intencionDetectada) || other.intencionDetectada == intencionDetectada)&&(identical(other.resultado, resultado) || other.resultado == resultado)&&const DeepCollectionEquality().equals(other._mensajes, _mensajes)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion)&&(identical(other.fechaUltimaInteraccion, fechaUltimaInteraccion) || other.fechaUltimaInteraccion == fechaUltimaInteraccion)&&(identical(other.gestionadoPor, gestionadoPor) || other.gestionadoPor == gestionadoPor)&&(identical(other.profesional, profesional) || other.profesional == profesional)&&(identical(other.fechaCita, fechaCita) || other.fechaCita == fechaCita));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pacienteNombre,pacienteTelefono,appointmentId,tipo,estado,intencionDetectada,resultado,const DeepCollectionEquality().hash(_mensajes),fechaCreacion,fechaUltimaInteraccion,gestionadoPor,profesional,fechaCita);

@override
String toString() {
  return 'WhatsAppConversation(id: $id, pacienteNombre: $pacienteNombre, pacienteTelefono: $pacienteTelefono, appointmentId: $appointmentId, tipo: $tipo, estado: $estado, intencionDetectada: $intencionDetectada, resultado: $resultado, mensajes: $mensajes, fechaCreacion: $fechaCreacion, fechaUltimaInteraccion: $fechaUltimaInteraccion, gestionadoPor: $gestionadoPor, profesional: $profesional, fechaCita: $fechaCita)';
}


}

/// @nodoc
abstract mixin class _$WhatsAppConversationCopyWith<$Res> implements $WhatsAppConversationCopyWith<$Res> {
  factory _$WhatsAppConversationCopyWith(_WhatsAppConversation value, $Res Function(_WhatsAppConversation) _then) = __$WhatsAppConversationCopyWithImpl;
@override @useResult
$Res call({
 String id, String pacienteNombre, String pacienteTelefono, String? appointmentId, String tipo, String estado, String? intencionDetectada, String? resultado, List<WhatsAppMessage> mensajes,@TimestampConverter() DateTime? fechaCreacion,@TimestampConverter() DateTime? fechaUltimaInteraccion, String gestionadoPor, String profesional,@TimestampConverter() DateTime? fechaCita
});




}
/// @nodoc
class __$WhatsAppConversationCopyWithImpl<$Res>
    implements _$WhatsAppConversationCopyWith<$Res> {
  __$WhatsAppConversationCopyWithImpl(this._self, this._then);

  final _WhatsAppConversation _self;
  final $Res Function(_WhatsAppConversation) _then;

/// Create a copy of WhatsAppConversation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pacienteNombre = null,Object? pacienteTelefono = null,Object? appointmentId = freezed,Object? tipo = null,Object? estado = null,Object? intencionDetectada = freezed,Object? resultado = freezed,Object? mensajes = null,Object? fechaCreacion = freezed,Object? fechaUltimaInteraccion = freezed,Object? gestionadoPor = null,Object? profesional = null,Object? fechaCita = freezed,}) {
  return _then(_WhatsAppConversation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pacienteNombre: null == pacienteNombre ? _self.pacienteNombre : pacienteNombre // ignore: cast_nullable_to_non_nullable
as String,pacienteTelefono: null == pacienteTelefono ? _self.pacienteTelefono : pacienteTelefono // ignore: cast_nullable_to_non_nullable
as String,appointmentId: freezed == appointmentId ? _self.appointmentId : appointmentId // ignore: cast_nullable_to_non_nullable
as String?,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String,intencionDetectada: freezed == intencionDetectada ? _self.intencionDetectada : intencionDetectada // ignore: cast_nullable_to_non_nullable
as String?,resultado: freezed == resultado ? _self.resultado : resultado // ignore: cast_nullable_to_non_nullable
as String?,mensajes: null == mensajes ? _self._mensajes : mensajes // ignore: cast_nullable_to_non_nullable
as List<WhatsAppMessage>,fechaCreacion: freezed == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaUltimaInteraccion: freezed == fechaUltimaInteraccion ? _self.fechaUltimaInteraccion : fechaUltimaInteraccion // ignore: cast_nullable_to_non_nullable
as DateTime?,gestionadoPor: null == gestionadoPor ? _self.gestionadoPor : gestionadoPor // ignore: cast_nullable_to_non_nullable
as String,profesional: null == profesional ? _self.profesional : profesional // ignore: cast_nullable_to_non_nullable
as String,fechaCita: freezed == fechaCita ? _self.fechaCita : fechaCita // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
