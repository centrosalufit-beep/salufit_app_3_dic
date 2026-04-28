// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clinni_appointment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClinniAppointment {

 String get id; String get pacienteNombre; String get pacienteTelefono;@TimestampConverter() DateTime get fechaCita; String get profesional; String get servicio; String get estado; bool get recordatorioEnviado;@TimestampConverter() DateTime? get fechaRecordatorio; String get deduplicationKey;@TimestampConverter() DateTime? get importadoEn; String get origenExcel; String get notas;
/// Create a copy of ClinniAppointment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClinniAppointmentCopyWith<ClinniAppointment> get copyWith => _$ClinniAppointmentCopyWithImpl<ClinniAppointment>(this as ClinniAppointment, _$identity);

  /// Serializes this ClinniAppointment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClinniAppointment&&(identical(other.id, id) || other.id == id)&&(identical(other.pacienteNombre, pacienteNombre) || other.pacienteNombre == pacienteNombre)&&(identical(other.pacienteTelefono, pacienteTelefono) || other.pacienteTelefono == pacienteTelefono)&&(identical(other.fechaCita, fechaCita) || other.fechaCita == fechaCita)&&(identical(other.profesional, profesional) || other.profesional == profesional)&&(identical(other.servicio, servicio) || other.servicio == servicio)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.recordatorioEnviado, recordatorioEnviado) || other.recordatorioEnviado == recordatorioEnviado)&&(identical(other.fechaRecordatorio, fechaRecordatorio) || other.fechaRecordatorio == fechaRecordatorio)&&(identical(other.deduplicationKey, deduplicationKey) || other.deduplicationKey == deduplicationKey)&&(identical(other.importadoEn, importadoEn) || other.importadoEn == importadoEn)&&(identical(other.origenExcel, origenExcel) || other.origenExcel == origenExcel)&&(identical(other.notas, notas) || other.notas == notas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pacienteNombre,pacienteTelefono,fechaCita,profesional,servicio,estado,recordatorioEnviado,fechaRecordatorio,deduplicationKey,importadoEn,origenExcel,notas);

@override
String toString() {
  return 'ClinniAppointment(id: $id, pacienteNombre: $pacienteNombre, pacienteTelefono: $pacienteTelefono, fechaCita: $fechaCita, profesional: $profesional, servicio: $servicio, estado: $estado, recordatorioEnviado: $recordatorioEnviado, fechaRecordatorio: $fechaRecordatorio, deduplicationKey: $deduplicationKey, importadoEn: $importadoEn, origenExcel: $origenExcel, notas: $notas)';
}


}

/// @nodoc
abstract mixin class $ClinniAppointmentCopyWith<$Res>  {
  factory $ClinniAppointmentCopyWith(ClinniAppointment value, $Res Function(ClinniAppointment) _then) = _$ClinniAppointmentCopyWithImpl;
@useResult
$Res call({
 String id, String pacienteNombre, String pacienteTelefono,@TimestampConverter() DateTime fechaCita, String profesional, String servicio, String estado, bool recordatorioEnviado,@TimestampConverter() DateTime? fechaRecordatorio, String deduplicationKey,@TimestampConverter() DateTime? importadoEn, String origenExcel, String notas
});




}
/// @nodoc
class _$ClinniAppointmentCopyWithImpl<$Res>
    implements $ClinniAppointmentCopyWith<$Res> {
  _$ClinniAppointmentCopyWithImpl(this._self, this._then);

  final ClinniAppointment _self;
  final $Res Function(ClinniAppointment) _then;

/// Create a copy of ClinniAppointment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pacienteNombre = null,Object? pacienteTelefono = null,Object? fechaCita = null,Object? profesional = null,Object? servicio = null,Object? estado = null,Object? recordatorioEnviado = null,Object? fechaRecordatorio = freezed,Object? deduplicationKey = null,Object? importadoEn = freezed,Object? origenExcel = null,Object? notas = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pacienteNombre: null == pacienteNombre ? _self.pacienteNombre : pacienteNombre // ignore: cast_nullable_to_non_nullable
as String,pacienteTelefono: null == pacienteTelefono ? _self.pacienteTelefono : pacienteTelefono // ignore: cast_nullable_to_non_nullable
as String,fechaCita: null == fechaCita ? _self.fechaCita : fechaCita // ignore: cast_nullable_to_non_nullable
as DateTime,profesional: null == profesional ? _self.profesional : profesional // ignore: cast_nullable_to_non_nullable
as String,servicio: null == servicio ? _self.servicio : servicio // ignore: cast_nullable_to_non_nullable
as String,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String,recordatorioEnviado: null == recordatorioEnviado ? _self.recordatorioEnviado : recordatorioEnviado // ignore: cast_nullable_to_non_nullable
as bool,fechaRecordatorio: freezed == fechaRecordatorio ? _self.fechaRecordatorio : fechaRecordatorio // ignore: cast_nullable_to_non_nullable
as DateTime?,deduplicationKey: null == deduplicationKey ? _self.deduplicationKey : deduplicationKey // ignore: cast_nullable_to_non_nullable
as String,importadoEn: freezed == importadoEn ? _self.importadoEn : importadoEn // ignore: cast_nullable_to_non_nullable
as DateTime?,origenExcel: null == origenExcel ? _self.origenExcel : origenExcel // ignore: cast_nullable_to_non_nullable
as String,notas: null == notas ? _self.notas : notas // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ClinniAppointment].
extension ClinniAppointmentPatterns on ClinniAppointment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClinniAppointment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClinniAppointment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClinniAppointment value)  $default,){
final _that = this;
switch (_that) {
case _ClinniAppointment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClinniAppointment value)?  $default,){
final _that = this;
switch (_that) {
case _ClinniAppointment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String pacienteNombre,  String pacienteTelefono, @TimestampConverter()  DateTime fechaCita,  String profesional,  String servicio,  String estado,  bool recordatorioEnviado, @TimestampConverter()  DateTime? fechaRecordatorio,  String deduplicationKey, @TimestampConverter()  DateTime? importadoEn,  String origenExcel,  String notas)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClinniAppointment() when $default != null:
return $default(_that.id,_that.pacienteNombre,_that.pacienteTelefono,_that.fechaCita,_that.profesional,_that.servicio,_that.estado,_that.recordatorioEnviado,_that.fechaRecordatorio,_that.deduplicationKey,_that.importadoEn,_that.origenExcel,_that.notas);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String pacienteNombre,  String pacienteTelefono, @TimestampConverter()  DateTime fechaCita,  String profesional,  String servicio,  String estado,  bool recordatorioEnviado, @TimestampConverter()  DateTime? fechaRecordatorio,  String deduplicationKey, @TimestampConverter()  DateTime? importadoEn,  String origenExcel,  String notas)  $default,) {final _that = this;
switch (_that) {
case _ClinniAppointment():
return $default(_that.id,_that.pacienteNombre,_that.pacienteTelefono,_that.fechaCita,_that.profesional,_that.servicio,_that.estado,_that.recordatorioEnviado,_that.fechaRecordatorio,_that.deduplicationKey,_that.importadoEn,_that.origenExcel,_that.notas);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String pacienteNombre,  String pacienteTelefono, @TimestampConverter()  DateTime fechaCita,  String profesional,  String servicio,  String estado,  bool recordatorioEnviado, @TimestampConverter()  DateTime? fechaRecordatorio,  String deduplicationKey, @TimestampConverter()  DateTime? importadoEn,  String origenExcel,  String notas)?  $default,) {final _that = this;
switch (_that) {
case _ClinniAppointment() when $default != null:
return $default(_that.id,_that.pacienteNombre,_that.pacienteTelefono,_that.fechaCita,_that.profesional,_that.servicio,_that.estado,_that.recordatorioEnviado,_that.fechaRecordatorio,_that.deduplicationKey,_that.importadoEn,_that.origenExcel,_that.notas);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClinniAppointment implements ClinniAppointment {
  const _ClinniAppointment({required this.id, required this.pacienteNombre, required this.pacienteTelefono, @TimestampConverter() required this.fechaCita, required this.profesional, this.servicio = '', this.estado = 'pendiente', this.recordatorioEnviado = false, @TimestampConverter() this.fechaRecordatorio, this.deduplicationKey = '', @TimestampConverter() this.importadoEn, this.origenExcel = '', this.notas = ''});
  factory _ClinniAppointment.fromJson(Map<String, dynamic> json) => _$ClinniAppointmentFromJson(json);

@override final  String id;
@override final  String pacienteNombre;
@override final  String pacienteTelefono;
@override@TimestampConverter() final  DateTime fechaCita;
@override final  String profesional;
@override@JsonKey() final  String servicio;
@override@JsonKey() final  String estado;
@override@JsonKey() final  bool recordatorioEnviado;
@override@TimestampConverter() final  DateTime? fechaRecordatorio;
@override@JsonKey() final  String deduplicationKey;
@override@TimestampConverter() final  DateTime? importadoEn;
@override@JsonKey() final  String origenExcel;
@override@JsonKey() final  String notas;

/// Create a copy of ClinniAppointment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClinniAppointmentCopyWith<_ClinniAppointment> get copyWith => __$ClinniAppointmentCopyWithImpl<_ClinniAppointment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClinniAppointmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClinniAppointment&&(identical(other.id, id) || other.id == id)&&(identical(other.pacienteNombre, pacienteNombre) || other.pacienteNombre == pacienteNombre)&&(identical(other.pacienteTelefono, pacienteTelefono) || other.pacienteTelefono == pacienteTelefono)&&(identical(other.fechaCita, fechaCita) || other.fechaCita == fechaCita)&&(identical(other.profesional, profesional) || other.profesional == profesional)&&(identical(other.servicio, servicio) || other.servicio == servicio)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.recordatorioEnviado, recordatorioEnviado) || other.recordatorioEnviado == recordatorioEnviado)&&(identical(other.fechaRecordatorio, fechaRecordatorio) || other.fechaRecordatorio == fechaRecordatorio)&&(identical(other.deduplicationKey, deduplicationKey) || other.deduplicationKey == deduplicationKey)&&(identical(other.importadoEn, importadoEn) || other.importadoEn == importadoEn)&&(identical(other.origenExcel, origenExcel) || other.origenExcel == origenExcel)&&(identical(other.notas, notas) || other.notas == notas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pacienteNombre,pacienteTelefono,fechaCita,profesional,servicio,estado,recordatorioEnviado,fechaRecordatorio,deduplicationKey,importadoEn,origenExcel,notas);

@override
String toString() {
  return 'ClinniAppointment(id: $id, pacienteNombre: $pacienteNombre, pacienteTelefono: $pacienteTelefono, fechaCita: $fechaCita, profesional: $profesional, servicio: $servicio, estado: $estado, recordatorioEnviado: $recordatorioEnviado, fechaRecordatorio: $fechaRecordatorio, deduplicationKey: $deduplicationKey, importadoEn: $importadoEn, origenExcel: $origenExcel, notas: $notas)';
}


}

/// @nodoc
abstract mixin class _$ClinniAppointmentCopyWith<$Res> implements $ClinniAppointmentCopyWith<$Res> {
  factory _$ClinniAppointmentCopyWith(_ClinniAppointment value, $Res Function(_ClinniAppointment) _then) = __$ClinniAppointmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String pacienteNombre, String pacienteTelefono,@TimestampConverter() DateTime fechaCita, String profesional, String servicio, String estado, bool recordatorioEnviado,@TimestampConverter() DateTime? fechaRecordatorio, String deduplicationKey,@TimestampConverter() DateTime? importadoEn, String origenExcel, String notas
});




}
/// @nodoc
class __$ClinniAppointmentCopyWithImpl<$Res>
    implements _$ClinniAppointmentCopyWith<$Res> {
  __$ClinniAppointmentCopyWithImpl(this._self, this._then);

  final _ClinniAppointment _self;
  final $Res Function(_ClinniAppointment) _then;

/// Create a copy of ClinniAppointment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pacienteNombre = null,Object? pacienteTelefono = null,Object? fechaCita = null,Object? profesional = null,Object? servicio = null,Object? estado = null,Object? recordatorioEnviado = null,Object? fechaRecordatorio = freezed,Object? deduplicationKey = null,Object? importadoEn = freezed,Object? origenExcel = null,Object? notas = null,}) {
  return _then(_ClinniAppointment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pacienteNombre: null == pacienteNombre ? _self.pacienteNombre : pacienteNombre // ignore: cast_nullable_to_non_nullable
as String,pacienteTelefono: null == pacienteTelefono ? _self.pacienteTelefono : pacienteTelefono // ignore: cast_nullable_to_non_nullable
as String,fechaCita: null == fechaCita ? _self.fechaCita : fechaCita // ignore: cast_nullable_to_non_nullable
as DateTime,profesional: null == profesional ? _self.profesional : profesional // ignore: cast_nullable_to_non_nullable
as String,servicio: null == servicio ? _self.servicio : servicio // ignore: cast_nullable_to_non_nullable
as String,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String,recordatorioEnviado: null == recordatorioEnviado ? _self.recordatorioEnviado : recordatorioEnviado // ignore: cast_nullable_to_non_nullable
as bool,fechaRecordatorio: freezed == fechaRecordatorio ? _self.fechaRecordatorio : fechaRecordatorio // ignore: cast_nullable_to_non_nullable
as DateTime?,deduplicationKey: null == deduplicationKey ? _self.deduplicationKey : deduplicationKey // ignore: cast_nullable_to_non_nullable
as String,importadoEn: freezed == importadoEn ? _self.importadoEn : importadoEn // ignore: cast_nullable_to_non_nullable
as DateTime?,origenExcel: null == origenExcel ? _self.origenExcel : origenExcel // ignore: cast_nullable_to_non_nullable
as String,notas: null == notas ? _self.notas : notas // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
