// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'clinic_info_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DayHours {

 String get abre; String get cierra;
/// Create a copy of DayHours
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayHoursCopyWith<DayHours> get copyWith => _$DayHoursCopyWithImpl<DayHours>(this as DayHours, _$identity);

  /// Serializes this DayHours to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayHours&&(identical(other.abre, abre) || other.abre == abre)&&(identical(other.cierra, cierra) || other.cierra == cierra));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,abre,cierra);

@override
String toString() {
  return 'DayHours(abre: $abre, cierra: $cierra)';
}


}

/// @nodoc
abstract mixin class $DayHoursCopyWith<$Res>  {
  factory $DayHoursCopyWith(DayHours value, $Res Function(DayHours) _then) = _$DayHoursCopyWithImpl;
@useResult
$Res call({
 String abre, String cierra
});




}
/// @nodoc
class _$DayHoursCopyWithImpl<$Res>
    implements $DayHoursCopyWith<$Res> {
  _$DayHoursCopyWithImpl(this._self, this._then);

  final DayHours _self;
  final $Res Function(DayHours) _then;

/// Create a copy of DayHours
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? abre = null,Object? cierra = null,}) {
  return _then(_self.copyWith(
abre: null == abre ? _self.abre : abre // ignore: cast_nullable_to_non_nullable
as String,cierra: null == cierra ? _self.cierra : cierra // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DayHours].
extension DayHoursPatterns on DayHours {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayHours value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayHours() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayHours value)  $default,){
final _that = this;
switch (_that) {
case _DayHours():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayHours value)?  $default,){
final _that = this;
switch (_that) {
case _DayHours() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String abre,  String cierra)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayHours() when $default != null:
return $default(_that.abre,_that.cierra);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String abre,  String cierra)  $default,) {final _that = this;
switch (_that) {
case _DayHours():
return $default(_that.abre,_that.cierra);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String abre,  String cierra)?  $default,) {final _that = this;
switch (_that) {
case _DayHours() when $default != null:
return $default(_that.abre,_that.cierra);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayHours implements DayHours {
  const _DayHours({this.abre = '09:00', this.cierra = '20:00'});
  factory _DayHours.fromJson(Map<String, dynamic> json) => _$DayHoursFromJson(json);

@override@JsonKey() final  String abre;
@override@JsonKey() final  String cierra;

/// Create a copy of DayHours
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayHoursCopyWith<_DayHours> get copyWith => __$DayHoursCopyWithImpl<_DayHours>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayHoursToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayHours&&(identical(other.abre, abre) || other.abre == abre)&&(identical(other.cierra, cierra) || other.cierra == cierra));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,abre,cierra);

@override
String toString() {
  return 'DayHours(abre: $abre, cierra: $cierra)';
}


}

/// @nodoc
abstract mixin class _$DayHoursCopyWith<$Res> implements $DayHoursCopyWith<$Res> {
  factory _$DayHoursCopyWith(_DayHours value, $Res Function(_DayHours) _then) = __$DayHoursCopyWithImpl;
@override @useResult
$Res call({
 String abre, String cierra
});




}
/// @nodoc
class __$DayHoursCopyWithImpl<$Res>
    implements _$DayHoursCopyWith<$Res> {
  __$DayHoursCopyWithImpl(this._self, this._then);

  final _DayHours _self;
  final $Res Function(_DayHours) _then;

/// Create a copy of DayHours
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? abre = null,Object? cierra = null,}) {
  return _then(_DayHours(
abre: null == abre ? _self.abre : abre // ignore: cast_nullable_to_non_nullable
as String,cierra: null == cierra ? _self.cierra : cierra // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ServicioInfo {

 String get nombre; int? get precio; String? get descripcion;
/// Create a copy of ServicioInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServicioInfoCopyWith<ServicioInfo> get copyWith => _$ServicioInfoCopyWithImpl<ServicioInfo>(this as ServicioInfo, _$identity);

  /// Serializes this ServicioInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServicioInfo&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.precio, precio) || other.precio == precio)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,nombre,precio,descripcion);

@override
String toString() {
  return 'ServicioInfo(nombre: $nombre, precio: $precio, descripcion: $descripcion)';
}


}

/// @nodoc
abstract mixin class $ServicioInfoCopyWith<$Res>  {
  factory $ServicioInfoCopyWith(ServicioInfo value, $Res Function(ServicioInfo) _then) = _$ServicioInfoCopyWithImpl;
@useResult
$Res call({
 String nombre, int? precio, String? descripcion
});




}
/// @nodoc
class _$ServicioInfoCopyWithImpl<$Res>
    implements $ServicioInfoCopyWith<$Res> {
  _$ServicioInfoCopyWithImpl(this._self, this._then);

  final ServicioInfo _self;
  final $Res Function(ServicioInfo) _then;

/// Create a copy of ServicioInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nombre = null,Object? precio = freezed,Object? descripcion = freezed,}) {
  return _then(_self.copyWith(
nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,precio: freezed == precio ? _self.precio : precio // ignore: cast_nullable_to_non_nullable
as int?,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ServicioInfo].
extension ServicioInfoPatterns on ServicioInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServicioInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServicioInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServicioInfo value)  $default,){
final _that = this;
switch (_that) {
case _ServicioInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServicioInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ServicioInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String nombre,  int? precio,  String? descripcion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServicioInfo() when $default != null:
return $default(_that.nombre,_that.precio,_that.descripcion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String nombre,  int? precio,  String? descripcion)  $default,) {final _that = this;
switch (_that) {
case _ServicioInfo():
return $default(_that.nombre,_that.precio,_that.descripcion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String nombre,  int? precio,  String? descripcion)?  $default,) {final _that = this;
switch (_that) {
case _ServicioInfo() when $default != null:
return $default(_that.nombre,_that.precio,_that.descripcion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServicioInfo implements ServicioInfo {
  const _ServicioInfo({this.nombre = '', this.precio, this.descripcion});
  factory _ServicioInfo.fromJson(Map<String, dynamic> json) => _$ServicioInfoFromJson(json);

@override@JsonKey() final  String nombre;
@override final  int? precio;
@override final  String? descripcion;

/// Create a copy of ServicioInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServicioInfoCopyWith<_ServicioInfo> get copyWith => __$ServicioInfoCopyWithImpl<_ServicioInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServicioInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServicioInfo&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.precio, precio) || other.precio == precio)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,nombre,precio,descripcion);

@override
String toString() {
  return 'ServicioInfo(nombre: $nombre, precio: $precio, descripcion: $descripcion)';
}


}

/// @nodoc
abstract mixin class _$ServicioInfoCopyWith<$Res> implements $ServicioInfoCopyWith<$Res> {
  factory _$ServicioInfoCopyWith(_ServicioInfo value, $Res Function(_ServicioInfo) _then) = __$ServicioInfoCopyWithImpl;
@override @useResult
$Res call({
 String nombre, int? precio, String? descripcion
});




}
/// @nodoc
class __$ServicioInfoCopyWithImpl<$Res>
    implements _$ServicioInfoCopyWith<$Res> {
  __$ServicioInfoCopyWithImpl(this._self, this._then);

  final _ServicioInfo _self;
  final $Res Function(_ServicioInfo) _then;

/// Create a copy of ServicioInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nombre = null,Object? precio = freezed,Object? descripcion = freezed,}) {
  return _then(_ServicioInfo(
nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,precio: freezed == precio ? _self.precio : precio // ignore: cast_nullable_to_non_nullable
as int?,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ClinicInfo {

 Map<String, DayHours?> get horarios; String get direccion; String get googleMapsUrl; String get telefonoRecepcion; String get parking; String get comoLlegar; String get primeraVisita; List<ServicioInfo> get servicios; String get bienvenidaNuevoPaciente;
/// Create a copy of ClinicInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClinicInfoCopyWith<ClinicInfo> get copyWith => _$ClinicInfoCopyWithImpl<ClinicInfo>(this as ClinicInfo, _$identity);

  /// Serializes this ClinicInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClinicInfo&&const DeepCollectionEquality().equals(other.horarios, horarios)&&(identical(other.direccion, direccion) || other.direccion == direccion)&&(identical(other.googleMapsUrl, googleMapsUrl) || other.googleMapsUrl == googleMapsUrl)&&(identical(other.telefonoRecepcion, telefonoRecepcion) || other.telefonoRecepcion == telefonoRecepcion)&&(identical(other.parking, parking) || other.parking == parking)&&(identical(other.comoLlegar, comoLlegar) || other.comoLlegar == comoLlegar)&&(identical(other.primeraVisita, primeraVisita) || other.primeraVisita == primeraVisita)&&const DeepCollectionEquality().equals(other.servicios, servicios)&&(identical(other.bienvenidaNuevoPaciente, bienvenidaNuevoPaciente) || other.bienvenidaNuevoPaciente == bienvenidaNuevoPaciente));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(horarios),direccion,googleMapsUrl,telefonoRecepcion,parking,comoLlegar,primeraVisita,const DeepCollectionEquality().hash(servicios),bienvenidaNuevoPaciente);

@override
String toString() {
  return 'ClinicInfo(horarios: $horarios, direccion: $direccion, googleMapsUrl: $googleMapsUrl, telefonoRecepcion: $telefonoRecepcion, parking: $parking, comoLlegar: $comoLlegar, primeraVisita: $primeraVisita, servicios: $servicios, bienvenidaNuevoPaciente: $bienvenidaNuevoPaciente)';
}


}

/// @nodoc
abstract mixin class $ClinicInfoCopyWith<$Res>  {
  factory $ClinicInfoCopyWith(ClinicInfo value, $Res Function(ClinicInfo) _then) = _$ClinicInfoCopyWithImpl;
@useResult
$Res call({
 Map<String, DayHours?> horarios, String direccion, String googleMapsUrl, String telefonoRecepcion, String parking, String comoLlegar, String primeraVisita, List<ServicioInfo> servicios, String bienvenidaNuevoPaciente
});




}
/// @nodoc
class _$ClinicInfoCopyWithImpl<$Res>
    implements $ClinicInfoCopyWith<$Res> {
  _$ClinicInfoCopyWithImpl(this._self, this._then);

  final ClinicInfo _self;
  final $Res Function(ClinicInfo) _then;

/// Create a copy of ClinicInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? horarios = null,Object? direccion = null,Object? googleMapsUrl = null,Object? telefonoRecepcion = null,Object? parking = null,Object? comoLlegar = null,Object? primeraVisita = null,Object? servicios = null,Object? bienvenidaNuevoPaciente = null,}) {
  return _then(_self.copyWith(
horarios: null == horarios ? _self.horarios : horarios // ignore: cast_nullable_to_non_nullable
as Map<String, DayHours?>,direccion: null == direccion ? _self.direccion : direccion // ignore: cast_nullable_to_non_nullable
as String,googleMapsUrl: null == googleMapsUrl ? _self.googleMapsUrl : googleMapsUrl // ignore: cast_nullable_to_non_nullable
as String,telefonoRecepcion: null == telefonoRecepcion ? _self.telefonoRecepcion : telefonoRecepcion // ignore: cast_nullable_to_non_nullable
as String,parking: null == parking ? _self.parking : parking // ignore: cast_nullable_to_non_nullable
as String,comoLlegar: null == comoLlegar ? _self.comoLlegar : comoLlegar // ignore: cast_nullable_to_non_nullable
as String,primeraVisita: null == primeraVisita ? _self.primeraVisita : primeraVisita // ignore: cast_nullable_to_non_nullable
as String,servicios: null == servicios ? _self.servicios : servicios // ignore: cast_nullable_to_non_nullable
as List<ServicioInfo>,bienvenidaNuevoPaciente: null == bienvenidaNuevoPaciente ? _self.bienvenidaNuevoPaciente : bienvenidaNuevoPaciente // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ClinicInfo].
extension ClinicInfoPatterns on ClinicInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClinicInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClinicInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClinicInfo value)  $default,){
final _that = this;
switch (_that) {
case _ClinicInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClinicInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ClinicInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, DayHours?> horarios,  String direccion,  String googleMapsUrl,  String telefonoRecepcion,  String parking,  String comoLlegar,  String primeraVisita,  List<ServicioInfo> servicios,  String bienvenidaNuevoPaciente)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClinicInfo() when $default != null:
return $default(_that.horarios,_that.direccion,_that.googleMapsUrl,_that.telefonoRecepcion,_that.parking,_that.comoLlegar,_that.primeraVisita,_that.servicios,_that.bienvenidaNuevoPaciente);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, DayHours?> horarios,  String direccion,  String googleMapsUrl,  String telefonoRecepcion,  String parking,  String comoLlegar,  String primeraVisita,  List<ServicioInfo> servicios,  String bienvenidaNuevoPaciente)  $default,) {final _that = this;
switch (_that) {
case _ClinicInfo():
return $default(_that.horarios,_that.direccion,_that.googleMapsUrl,_that.telefonoRecepcion,_that.parking,_that.comoLlegar,_that.primeraVisita,_that.servicios,_that.bienvenidaNuevoPaciente);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, DayHours?> horarios,  String direccion,  String googleMapsUrl,  String telefonoRecepcion,  String parking,  String comoLlegar,  String primeraVisita,  List<ServicioInfo> servicios,  String bienvenidaNuevoPaciente)?  $default,) {final _that = this;
switch (_that) {
case _ClinicInfo() when $default != null:
return $default(_that.horarios,_that.direccion,_that.googleMapsUrl,_that.telefonoRecepcion,_that.parking,_that.comoLlegar,_that.primeraVisita,_that.servicios,_that.bienvenidaNuevoPaciente);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClinicInfo implements ClinicInfo {
  const _ClinicInfo({final  Map<String, DayHours?> horarios = const <String, DayHours?>{}, this.direccion = '', this.googleMapsUrl = '', this.telefonoRecepcion = '', this.parking = '', this.comoLlegar = '', this.primeraVisita = '', final  List<ServicioInfo> servicios = const <ServicioInfo>[], this.bienvenidaNuevoPaciente = ''}): _horarios = horarios,_servicios = servicios;
  factory _ClinicInfo.fromJson(Map<String, dynamic> json) => _$ClinicInfoFromJson(json);

 final  Map<String, DayHours?> _horarios;
@override@JsonKey() Map<String, DayHours?> get horarios {
  if (_horarios is EqualUnmodifiableMapView) return _horarios;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_horarios);
}

@override@JsonKey() final  String direccion;
@override@JsonKey() final  String googleMapsUrl;
@override@JsonKey() final  String telefonoRecepcion;
@override@JsonKey() final  String parking;
@override@JsonKey() final  String comoLlegar;
@override@JsonKey() final  String primeraVisita;
 final  List<ServicioInfo> _servicios;
@override@JsonKey() List<ServicioInfo> get servicios {
  if (_servicios is EqualUnmodifiableListView) return _servicios;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_servicios);
}

@override@JsonKey() final  String bienvenidaNuevoPaciente;

/// Create a copy of ClinicInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClinicInfoCopyWith<_ClinicInfo> get copyWith => __$ClinicInfoCopyWithImpl<_ClinicInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClinicInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClinicInfo&&const DeepCollectionEquality().equals(other._horarios, _horarios)&&(identical(other.direccion, direccion) || other.direccion == direccion)&&(identical(other.googleMapsUrl, googleMapsUrl) || other.googleMapsUrl == googleMapsUrl)&&(identical(other.telefonoRecepcion, telefonoRecepcion) || other.telefonoRecepcion == telefonoRecepcion)&&(identical(other.parking, parking) || other.parking == parking)&&(identical(other.comoLlegar, comoLlegar) || other.comoLlegar == comoLlegar)&&(identical(other.primeraVisita, primeraVisita) || other.primeraVisita == primeraVisita)&&const DeepCollectionEquality().equals(other._servicios, _servicios)&&(identical(other.bienvenidaNuevoPaciente, bienvenidaNuevoPaciente) || other.bienvenidaNuevoPaciente == bienvenidaNuevoPaciente));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_horarios),direccion,googleMapsUrl,telefonoRecepcion,parking,comoLlegar,primeraVisita,const DeepCollectionEquality().hash(_servicios),bienvenidaNuevoPaciente);

@override
String toString() {
  return 'ClinicInfo(horarios: $horarios, direccion: $direccion, googleMapsUrl: $googleMapsUrl, telefonoRecepcion: $telefonoRecepcion, parking: $parking, comoLlegar: $comoLlegar, primeraVisita: $primeraVisita, servicios: $servicios, bienvenidaNuevoPaciente: $bienvenidaNuevoPaciente)';
}


}

/// @nodoc
abstract mixin class _$ClinicInfoCopyWith<$Res> implements $ClinicInfoCopyWith<$Res> {
  factory _$ClinicInfoCopyWith(_ClinicInfo value, $Res Function(_ClinicInfo) _then) = __$ClinicInfoCopyWithImpl;
@override @useResult
$Res call({
 Map<String, DayHours?> horarios, String direccion, String googleMapsUrl, String telefonoRecepcion, String parking, String comoLlegar, String primeraVisita, List<ServicioInfo> servicios, String bienvenidaNuevoPaciente
});




}
/// @nodoc
class __$ClinicInfoCopyWithImpl<$Res>
    implements _$ClinicInfoCopyWith<$Res> {
  __$ClinicInfoCopyWithImpl(this._self, this._then);

  final _ClinicInfo _self;
  final $Res Function(_ClinicInfo) _then;

/// Create a copy of ClinicInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? horarios = null,Object? direccion = null,Object? googleMapsUrl = null,Object? telefonoRecepcion = null,Object? parking = null,Object? comoLlegar = null,Object? primeraVisita = null,Object? servicios = null,Object? bienvenidaNuevoPaciente = null,}) {
  return _then(_ClinicInfo(
horarios: null == horarios ? _self._horarios : horarios // ignore: cast_nullable_to_non_nullable
as Map<String, DayHours?>,direccion: null == direccion ? _self.direccion : direccion // ignore: cast_nullable_to_non_nullable
as String,googleMapsUrl: null == googleMapsUrl ? _self.googleMapsUrl : googleMapsUrl // ignore: cast_nullable_to_non_nullable
as String,telefonoRecepcion: null == telefonoRecepcion ? _self.telefonoRecepcion : telefonoRecepcion // ignore: cast_nullable_to_non_nullable
as String,parking: null == parking ? _self.parking : parking // ignore: cast_nullable_to_non_nullable
as String,comoLlegar: null == comoLlegar ? _self.comoLlegar : comoLlegar // ignore: cast_nullable_to_non_nullable
as String,primeraVisita: null == primeraVisita ? _self.primeraVisita : primeraVisita // ignore: cast_nullable_to_non_nullable
as String,servicios: null == servicios ? _self._servicios : servicios // ignore: cast_nullable_to_non_nullable
as List<ServicioInfo>,bienvenidaNuevoPaciente: null == bienvenidaNuevoPaciente ? _self.bienvenidaNuevoPaciente : bienvenidaNuevoPaciente // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ClinicHoliday {

 String get fecha;// ISO YYYY-MM-DD (también es el doc ID)
 String get motivo; String get tipo;// festivo | cerrado_excepcional | horario_reducido
 DayHours? get horarioEspecial;
/// Create a copy of ClinicHoliday
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClinicHolidayCopyWith<ClinicHoliday> get copyWith => _$ClinicHolidayCopyWithImpl<ClinicHoliday>(this as ClinicHoliday, _$identity);

  /// Serializes this ClinicHoliday to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClinicHoliday&&(identical(other.fecha, fecha) || other.fecha == fecha)&&(identical(other.motivo, motivo) || other.motivo == motivo)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.horarioEspecial, horarioEspecial) || other.horarioEspecial == horarioEspecial));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fecha,motivo,tipo,horarioEspecial);

@override
String toString() {
  return 'ClinicHoliday(fecha: $fecha, motivo: $motivo, tipo: $tipo, horarioEspecial: $horarioEspecial)';
}


}

/// @nodoc
abstract mixin class $ClinicHolidayCopyWith<$Res>  {
  factory $ClinicHolidayCopyWith(ClinicHoliday value, $Res Function(ClinicHoliday) _then) = _$ClinicHolidayCopyWithImpl;
@useResult
$Res call({
 String fecha, String motivo, String tipo, DayHours? horarioEspecial
});


$DayHoursCopyWith<$Res>? get horarioEspecial;

}
/// @nodoc
class _$ClinicHolidayCopyWithImpl<$Res>
    implements $ClinicHolidayCopyWith<$Res> {
  _$ClinicHolidayCopyWithImpl(this._self, this._then);

  final ClinicHoliday _self;
  final $Res Function(ClinicHoliday) _then;

/// Create a copy of ClinicHoliday
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fecha = null,Object? motivo = null,Object? tipo = null,Object? horarioEspecial = freezed,}) {
  return _then(_self.copyWith(
fecha: null == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as String,motivo: null == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String,horarioEspecial: freezed == horarioEspecial ? _self.horarioEspecial : horarioEspecial // ignore: cast_nullable_to_non_nullable
as DayHours?,
  ));
}
/// Create a copy of ClinicHoliday
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHoursCopyWith<$Res>? get horarioEspecial {
    if (_self.horarioEspecial == null) {
    return null;
  }

  return $DayHoursCopyWith<$Res>(_self.horarioEspecial!, (value) {
    return _then(_self.copyWith(horarioEspecial: value));
  });
}
}


/// Adds pattern-matching-related methods to [ClinicHoliday].
extension ClinicHolidayPatterns on ClinicHoliday {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClinicHoliday value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClinicHoliday() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClinicHoliday value)  $default,){
final _that = this;
switch (_that) {
case _ClinicHoliday():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClinicHoliday value)?  $default,){
final _that = this;
switch (_that) {
case _ClinicHoliday() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fecha,  String motivo,  String tipo,  DayHours? horarioEspecial)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClinicHoliday() when $default != null:
return $default(_that.fecha,_that.motivo,_that.tipo,_that.horarioEspecial);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fecha,  String motivo,  String tipo,  DayHours? horarioEspecial)  $default,) {final _that = this;
switch (_that) {
case _ClinicHoliday():
return $default(_that.fecha,_that.motivo,_that.tipo,_that.horarioEspecial);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fecha,  String motivo,  String tipo,  DayHours? horarioEspecial)?  $default,) {final _that = this;
switch (_that) {
case _ClinicHoliday() when $default != null:
return $default(_that.fecha,_that.motivo,_that.tipo,_that.horarioEspecial);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClinicHoliday implements ClinicHoliday {
  const _ClinicHoliday({this.fecha = '', this.motivo = '', this.tipo = 'festivo', this.horarioEspecial});
  factory _ClinicHoliday.fromJson(Map<String, dynamic> json) => _$ClinicHolidayFromJson(json);

@override@JsonKey() final  String fecha;
// ISO YYYY-MM-DD (también es el doc ID)
@override@JsonKey() final  String motivo;
@override@JsonKey() final  String tipo;
// festivo | cerrado_excepcional | horario_reducido
@override final  DayHours? horarioEspecial;

/// Create a copy of ClinicHoliday
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClinicHolidayCopyWith<_ClinicHoliday> get copyWith => __$ClinicHolidayCopyWithImpl<_ClinicHoliday>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClinicHolidayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClinicHoliday&&(identical(other.fecha, fecha) || other.fecha == fecha)&&(identical(other.motivo, motivo) || other.motivo == motivo)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.horarioEspecial, horarioEspecial) || other.horarioEspecial == horarioEspecial));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fecha,motivo,tipo,horarioEspecial);

@override
String toString() {
  return 'ClinicHoliday(fecha: $fecha, motivo: $motivo, tipo: $tipo, horarioEspecial: $horarioEspecial)';
}


}

/// @nodoc
abstract mixin class _$ClinicHolidayCopyWith<$Res> implements $ClinicHolidayCopyWith<$Res> {
  factory _$ClinicHolidayCopyWith(_ClinicHoliday value, $Res Function(_ClinicHoliday) _then) = __$ClinicHolidayCopyWithImpl;
@override @useResult
$Res call({
 String fecha, String motivo, String tipo, DayHours? horarioEspecial
});


@override $DayHoursCopyWith<$Res>? get horarioEspecial;

}
/// @nodoc
class __$ClinicHolidayCopyWithImpl<$Res>
    implements _$ClinicHolidayCopyWith<$Res> {
  __$ClinicHolidayCopyWithImpl(this._self, this._then);

  final _ClinicHoliday _self;
  final $Res Function(_ClinicHoliday) _then;

/// Create a copy of ClinicHoliday
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fecha = null,Object? motivo = null,Object? tipo = null,Object? horarioEspecial = freezed,}) {
  return _then(_ClinicHoliday(
fecha: null == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as String,motivo: null == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String,horarioEspecial: freezed == horarioEspecial ? _self.horarioEspecial : horarioEspecial // ignore: cast_nullable_to_non_nullable
as DayHours?,
  ));
}

/// Create a copy of ClinicHoliday
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayHoursCopyWith<$Res>? get horarioEspecial {
    if (_self.horarioEspecial == null) {
    return null;
  }

  return $DayHoursCopyWith<$Res>(_self.horarioEspecial!, (value) {
    return _then(_self.copyWith(horarioEspecial: value));
  });
}
}

/// @nodoc
mixin _$ProfessionalAbsence {

 String get id; String get profesionalId; String get profesionalNombre; DateTime? get desde; DateTime? get hasta; String get motivo;
/// Create a copy of ProfessionalAbsence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfessionalAbsenceCopyWith<ProfessionalAbsence> get copyWith => _$ProfessionalAbsenceCopyWithImpl<ProfessionalAbsence>(this as ProfessionalAbsence, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfessionalAbsence&&(identical(other.id, id) || other.id == id)&&(identical(other.profesionalId, profesionalId) || other.profesionalId == profesionalId)&&(identical(other.profesionalNombre, profesionalNombre) || other.profesionalNombre == profesionalNombre)&&(identical(other.desde, desde) || other.desde == desde)&&(identical(other.hasta, hasta) || other.hasta == hasta)&&(identical(other.motivo, motivo) || other.motivo == motivo));
}


@override
int get hashCode => Object.hash(runtimeType,id,profesionalId,profesionalNombre,desde,hasta,motivo);

@override
String toString() {
  return 'ProfessionalAbsence(id: $id, profesionalId: $profesionalId, profesionalNombre: $profesionalNombre, desde: $desde, hasta: $hasta, motivo: $motivo)';
}


}

/// @nodoc
abstract mixin class $ProfessionalAbsenceCopyWith<$Res>  {
  factory $ProfessionalAbsenceCopyWith(ProfessionalAbsence value, $Res Function(ProfessionalAbsence) _then) = _$ProfessionalAbsenceCopyWithImpl;
@useResult
$Res call({
 String id, String profesionalId, String profesionalNombre, DateTime? desde, DateTime? hasta, String motivo
});




}
/// @nodoc
class _$ProfessionalAbsenceCopyWithImpl<$Res>
    implements $ProfessionalAbsenceCopyWith<$Res> {
  _$ProfessionalAbsenceCopyWithImpl(this._self, this._then);

  final ProfessionalAbsence _self;
  final $Res Function(ProfessionalAbsence) _then;

/// Create a copy of ProfessionalAbsence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? profesionalId = null,Object? profesionalNombre = null,Object? desde = freezed,Object? hasta = freezed,Object? motivo = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,profesionalId: null == profesionalId ? _self.profesionalId : profesionalId // ignore: cast_nullable_to_non_nullable
as String,profesionalNombre: null == profesionalNombre ? _self.profesionalNombre : profesionalNombre // ignore: cast_nullable_to_non_nullable
as String,desde: freezed == desde ? _self.desde : desde // ignore: cast_nullable_to_non_nullable
as DateTime?,hasta: freezed == hasta ? _self.hasta : hasta // ignore: cast_nullable_to_non_nullable
as DateTime?,motivo: null == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfessionalAbsence].
extension ProfessionalAbsencePatterns on ProfessionalAbsence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfessionalAbsence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfessionalAbsence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfessionalAbsence value)  $default,){
final _that = this;
switch (_that) {
case _ProfessionalAbsence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfessionalAbsence value)?  $default,){
final _that = this;
switch (_that) {
case _ProfessionalAbsence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String profesionalId,  String profesionalNombre,  DateTime? desde,  DateTime? hasta,  String motivo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfessionalAbsence() when $default != null:
return $default(_that.id,_that.profesionalId,_that.profesionalNombre,_that.desde,_that.hasta,_that.motivo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String profesionalId,  String profesionalNombre,  DateTime? desde,  DateTime? hasta,  String motivo)  $default,) {final _that = this;
switch (_that) {
case _ProfessionalAbsence():
return $default(_that.id,_that.profesionalId,_that.profesionalNombre,_that.desde,_that.hasta,_that.motivo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String profesionalId,  String profesionalNombre,  DateTime? desde,  DateTime? hasta,  String motivo)?  $default,) {final _that = this;
switch (_that) {
case _ProfessionalAbsence() when $default != null:
return $default(_that.id,_that.profesionalId,_that.profesionalNombre,_that.desde,_that.hasta,_that.motivo);case _:
  return null;

}
}

}

/// @nodoc


class _ProfessionalAbsence implements ProfessionalAbsence {
  const _ProfessionalAbsence({this.id = '', this.profesionalId = '', this.profesionalNombre = '', this.desde, this.hasta, this.motivo = ''});
  

@override@JsonKey() final  String id;
@override@JsonKey() final  String profesionalId;
@override@JsonKey() final  String profesionalNombre;
@override final  DateTime? desde;
@override final  DateTime? hasta;
@override@JsonKey() final  String motivo;

/// Create a copy of ProfessionalAbsence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfessionalAbsenceCopyWith<_ProfessionalAbsence> get copyWith => __$ProfessionalAbsenceCopyWithImpl<_ProfessionalAbsence>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfessionalAbsence&&(identical(other.id, id) || other.id == id)&&(identical(other.profesionalId, profesionalId) || other.profesionalId == profesionalId)&&(identical(other.profesionalNombre, profesionalNombre) || other.profesionalNombre == profesionalNombre)&&(identical(other.desde, desde) || other.desde == desde)&&(identical(other.hasta, hasta) || other.hasta == hasta)&&(identical(other.motivo, motivo) || other.motivo == motivo));
}


@override
int get hashCode => Object.hash(runtimeType,id,profesionalId,profesionalNombre,desde,hasta,motivo);

@override
String toString() {
  return 'ProfessionalAbsence(id: $id, profesionalId: $profesionalId, profesionalNombre: $profesionalNombre, desde: $desde, hasta: $hasta, motivo: $motivo)';
}


}

/// @nodoc
abstract mixin class _$ProfessionalAbsenceCopyWith<$Res> implements $ProfessionalAbsenceCopyWith<$Res> {
  factory _$ProfessionalAbsenceCopyWith(_ProfessionalAbsence value, $Res Function(_ProfessionalAbsence) _then) = __$ProfessionalAbsenceCopyWithImpl;
@override @useResult
$Res call({
 String id, String profesionalId, String profesionalNombre, DateTime? desde, DateTime? hasta, String motivo
});




}
/// @nodoc
class __$ProfessionalAbsenceCopyWithImpl<$Res>
    implements _$ProfessionalAbsenceCopyWith<$Res> {
  __$ProfessionalAbsenceCopyWithImpl(this._self, this._then);

  final _ProfessionalAbsence _self;
  final $Res Function(_ProfessionalAbsence) _then;

/// Create a copy of ProfessionalAbsence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? profesionalId = null,Object? profesionalNombre = null,Object? desde = freezed,Object? hasta = freezed,Object? motivo = null,}) {
  return _then(_ProfessionalAbsence(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,profesionalId: null == profesionalId ? _self.profesionalId : profesionalId // ignore: cast_nullable_to_non_nullable
as String,profesionalNombre: null == profesionalNombre ? _self.profesionalNombre : profesionalNombre // ignore: cast_nullable_to_non_nullable
as String,desde: freezed == desde ? _self.desde : desde // ignore: cast_nullable_to_non_nullable
as DateTime?,hasta: freezed == hasta ? _self.hasta : hasta // ignore: cast_nullable_to_non_nullable
as DateTime?,motivo: null == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
