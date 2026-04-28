// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskModel {

 String get id; String get titulo; DateTime get fechaLimite; String get asignadorUid; String get asignadorNombre; String get asignadoUid; String get asignadoNombre; DateTime get fechaCreacion; String get descripcion; TaskEstado get estado; DateTime? get fechaActualizacion; DateTime? get fechaCompletada; String get grupoAsignacion;
/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskModelCopyWith<TaskModel> get copyWith => _$TaskModelCopyWithImpl<TaskModel>(this as TaskModel, _$identity);

  /// Serializes this TaskModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskModel&&(identical(other.id, id) || other.id == id)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.fechaLimite, fechaLimite) || other.fechaLimite == fechaLimite)&&(identical(other.asignadorUid, asignadorUid) || other.asignadorUid == asignadorUid)&&(identical(other.asignadorNombre, asignadorNombre) || other.asignadorNombre == asignadorNombre)&&(identical(other.asignadoUid, asignadoUid) || other.asignadoUid == asignadoUid)&&(identical(other.asignadoNombre, asignadoNombre) || other.asignadoNombre == asignadoNombre)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.fechaActualizacion, fechaActualizacion) || other.fechaActualizacion == fechaActualizacion)&&(identical(other.fechaCompletada, fechaCompletada) || other.fechaCompletada == fechaCompletada)&&(identical(other.grupoAsignacion, grupoAsignacion) || other.grupoAsignacion == grupoAsignacion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,titulo,fechaLimite,asignadorUid,asignadorNombre,asignadoUid,asignadoNombre,fechaCreacion,descripcion,estado,fechaActualizacion,fechaCompletada,grupoAsignacion);

@override
String toString() {
  return 'TaskModel(id: $id, titulo: $titulo, fechaLimite: $fechaLimite, asignadorUid: $asignadorUid, asignadorNombre: $asignadorNombre, asignadoUid: $asignadoUid, asignadoNombre: $asignadoNombre, fechaCreacion: $fechaCreacion, descripcion: $descripcion, estado: $estado, fechaActualizacion: $fechaActualizacion, fechaCompletada: $fechaCompletada, grupoAsignacion: $grupoAsignacion)';
}


}

/// @nodoc
abstract mixin class $TaskModelCopyWith<$Res>  {
  factory $TaskModelCopyWith(TaskModel value, $Res Function(TaskModel) _then) = _$TaskModelCopyWithImpl;
@useResult
$Res call({
 String id, String titulo, DateTime fechaLimite, String asignadorUid, String asignadorNombre, String asignadoUid, String asignadoNombre, DateTime fechaCreacion, String descripcion, TaskEstado estado, DateTime? fechaActualizacion, DateTime? fechaCompletada, String grupoAsignacion
});




}
/// @nodoc
class _$TaskModelCopyWithImpl<$Res>
    implements $TaskModelCopyWith<$Res> {
  _$TaskModelCopyWithImpl(this._self, this._then);

  final TaskModel _self;
  final $Res Function(TaskModel) _then;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? titulo = null,Object? fechaLimite = null,Object? asignadorUid = null,Object? asignadorNombre = null,Object? asignadoUid = null,Object? asignadoNombre = null,Object? fechaCreacion = null,Object? descripcion = null,Object? estado = null,Object? fechaActualizacion = freezed,Object? fechaCompletada = freezed,Object? grupoAsignacion = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,fechaLimite: null == fechaLimite ? _self.fechaLimite : fechaLimite // ignore: cast_nullable_to_non_nullable
as DateTime,asignadorUid: null == asignadorUid ? _self.asignadorUid : asignadorUid // ignore: cast_nullable_to_non_nullable
as String,asignadorNombre: null == asignadorNombre ? _self.asignadorNombre : asignadorNombre // ignore: cast_nullable_to_non_nullable
as String,asignadoUid: null == asignadoUid ? _self.asignadoUid : asignadoUid // ignore: cast_nullable_to_non_nullable
as String,asignadoNombre: null == asignadoNombre ? _self.asignadoNombre : asignadoNombre // ignore: cast_nullable_to_non_nullable
as String,fechaCreacion: null == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as TaskEstado,fechaActualizacion: freezed == fechaActualizacion ? _self.fechaActualizacion : fechaActualizacion // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaCompletada: freezed == fechaCompletada ? _self.fechaCompletada : fechaCompletada // ignore: cast_nullable_to_non_nullable
as DateTime?,grupoAsignacion: null == grupoAsignacion ? _self.grupoAsignacion : grupoAsignacion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskModel].
extension TaskModelPatterns on TaskModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskModel value)  $default,){
final _that = this;
switch (_that) {
case _TaskModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskModel value)?  $default,){
final _that = this;
switch (_that) {
case _TaskModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String titulo,  DateTime fechaLimite,  String asignadorUid,  String asignadorNombre,  String asignadoUid,  String asignadoNombre,  DateTime fechaCreacion,  String descripcion,  TaskEstado estado,  DateTime? fechaActualizacion,  DateTime? fechaCompletada,  String grupoAsignacion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskModel() when $default != null:
return $default(_that.id,_that.titulo,_that.fechaLimite,_that.asignadorUid,_that.asignadorNombre,_that.asignadoUid,_that.asignadoNombre,_that.fechaCreacion,_that.descripcion,_that.estado,_that.fechaActualizacion,_that.fechaCompletada,_that.grupoAsignacion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String titulo,  DateTime fechaLimite,  String asignadorUid,  String asignadorNombre,  String asignadoUid,  String asignadoNombre,  DateTime fechaCreacion,  String descripcion,  TaskEstado estado,  DateTime? fechaActualizacion,  DateTime? fechaCompletada,  String grupoAsignacion)  $default,) {final _that = this;
switch (_that) {
case _TaskModel():
return $default(_that.id,_that.titulo,_that.fechaLimite,_that.asignadorUid,_that.asignadorNombre,_that.asignadoUid,_that.asignadoNombre,_that.fechaCreacion,_that.descripcion,_that.estado,_that.fechaActualizacion,_that.fechaCompletada,_that.grupoAsignacion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String titulo,  DateTime fechaLimite,  String asignadorUid,  String asignadorNombre,  String asignadoUid,  String asignadoNombre,  DateTime fechaCreacion,  String descripcion,  TaskEstado estado,  DateTime? fechaActualizacion,  DateTime? fechaCompletada,  String grupoAsignacion)?  $default,) {final _that = this;
switch (_that) {
case _TaskModel() when $default != null:
return $default(_that.id,_that.titulo,_that.fechaLimite,_that.asignadorUid,_that.asignadorNombre,_that.asignadoUid,_that.asignadoNombre,_that.fechaCreacion,_that.descripcion,_that.estado,_that.fechaActualizacion,_that.fechaCompletada,_that.grupoAsignacion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskModel implements TaskModel {
  const _TaskModel({required this.id, required this.titulo, required this.fechaLimite, required this.asignadorUid, required this.asignadorNombre, required this.asignadoUid, required this.asignadoNombre, required this.fechaCreacion, this.descripcion = '', this.estado = TaskEstado.pendiente, this.fechaActualizacion, this.fechaCompletada, this.grupoAsignacion = ''});
  factory _TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);

@override final  String id;
@override final  String titulo;
@override final  DateTime fechaLimite;
@override final  String asignadorUid;
@override final  String asignadorNombre;
@override final  String asignadoUid;
@override final  String asignadoNombre;
@override final  DateTime fechaCreacion;
@override@JsonKey() final  String descripcion;
@override@JsonKey() final  TaskEstado estado;
@override final  DateTime? fechaActualizacion;
@override final  DateTime? fechaCompletada;
@override@JsonKey() final  String grupoAsignacion;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskModelCopyWith<_TaskModel> get copyWith => __$TaskModelCopyWithImpl<_TaskModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskModel&&(identical(other.id, id) || other.id == id)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.fechaLimite, fechaLimite) || other.fechaLimite == fechaLimite)&&(identical(other.asignadorUid, asignadorUid) || other.asignadorUid == asignadorUid)&&(identical(other.asignadorNombre, asignadorNombre) || other.asignadorNombre == asignadorNombre)&&(identical(other.asignadoUid, asignadoUid) || other.asignadoUid == asignadoUid)&&(identical(other.asignadoNombre, asignadoNombre) || other.asignadoNombre == asignadoNombre)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.fechaActualizacion, fechaActualizacion) || other.fechaActualizacion == fechaActualizacion)&&(identical(other.fechaCompletada, fechaCompletada) || other.fechaCompletada == fechaCompletada)&&(identical(other.grupoAsignacion, grupoAsignacion) || other.grupoAsignacion == grupoAsignacion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,titulo,fechaLimite,asignadorUid,asignadorNombre,asignadoUid,asignadoNombre,fechaCreacion,descripcion,estado,fechaActualizacion,fechaCompletada,grupoAsignacion);

@override
String toString() {
  return 'TaskModel(id: $id, titulo: $titulo, fechaLimite: $fechaLimite, asignadorUid: $asignadorUid, asignadorNombre: $asignadorNombre, asignadoUid: $asignadoUid, asignadoNombre: $asignadoNombre, fechaCreacion: $fechaCreacion, descripcion: $descripcion, estado: $estado, fechaActualizacion: $fechaActualizacion, fechaCompletada: $fechaCompletada, grupoAsignacion: $grupoAsignacion)';
}


}

/// @nodoc
abstract mixin class _$TaskModelCopyWith<$Res> implements $TaskModelCopyWith<$Res> {
  factory _$TaskModelCopyWith(_TaskModel value, $Res Function(_TaskModel) _then) = __$TaskModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String titulo, DateTime fechaLimite, String asignadorUid, String asignadorNombre, String asignadoUid, String asignadoNombre, DateTime fechaCreacion, String descripcion, TaskEstado estado, DateTime? fechaActualizacion, DateTime? fechaCompletada, String grupoAsignacion
});




}
/// @nodoc
class __$TaskModelCopyWithImpl<$Res>
    implements _$TaskModelCopyWith<$Res> {
  __$TaskModelCopyWithImpl(this._self, this._then);

  final _TaskModel _self;
  final $Res Function(_TaskModel) _then;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? titulo = null,Object? fechaLimite = null,Object? asignadorUid = null,Object? asignadorNombre = null,Object? asignadoUid = null,Object? asignadoNombre = null,Object? fechaCreacion = null,Object? descripcion = null,Object? estado = null,Object? fechaActualizacion = freezed,Object? fechaCompletada = freezed,Object? grupoAsignacion = null,}) {
  return _then(_TaskModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,fechaLimite: null == fechaLimite ? _self.fechaLimite : fechaLimite // ignore: cast_nullable_to_non_nullable
as DateTime,asignadorUid: null == asignadorUid ? _self.asignadorUid : asignadorUid // ignore: cast_nullable_to_non_nullable
as String,asignadorNombre: null == asignadorNombre ? _self.asignadorNombre : asignadorNombre // ignore: cast_nullable_to_non_nullable
as String,asignadoUid: null == asignadoUid ? _self.asignadoUid : asignadoUid // ignore: cast_nullable_to_non_nullable
as String,asignadoNombre: null == asignadoNombre ? _self.asignadoNombre : asignadoNombre // ignore: cast_nullable_to_non_nullable
as String,fechaCreacion: null == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as TaskEstado,fechaActualizacion: freezed == fechaActualizacion ? _self.fechaActualizacion : fechaActualizacion // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaCompletada: freezed == fechaCompletada ? _self.fechaCompletada : fechaCompletada // ignore: cast_nullable_to_non_nullable
as DateTime?,grupoAsignacion: null == grupoAsignacion ? _self.grupoAsignacion : grupoAsignacion // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
