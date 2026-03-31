// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserModel {

 String get uid; String get email; String get nombre;// Tolerante a null (devuelve vacío)
 String get nombreCompleto;// Tolerante a null
 String get numeroHistoria;// Tolerante a null
 String get role; bool get onboardingCompleted; int get tokensRestantes; bool get migrated; bool get termsAccepted;
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserModelCopyWith<UserModel> get copyWith => _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserModel&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.email, email) || other.email == email)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.nombreCompleto, nombreCompleto) || other.nombreCompleto == nombreCompleto)&&(identical(other.numeroHistoria, numeroHistoria) || other.numeroHistoria == numeroHistoria)&&(identical(other.role, role) || other.role == role)&&(identical(other.onboardingCompleted, onboardingCompleted) || other.onboardingCompleted == onboardingCompleted)&&(identical(other.tokensRestantes, tokensRestantes) || other.tokensRestantes == tokensRestantes)&&(identical(other.migrated, migrated) || other.migrated == migrated)&&(identical(other.termsAccepted, termsAccepted) || other.termsAccepted == termsAccepted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,email,nombre,nombreCompleto,numeroHistoria,role,onboardingCompleted,tokensRestantes,migrated,termsAccepted);

@override
String toString() {
  return 'UserModel(uid: $uid, email: $email, nombre: $nombre, nombreCompleto: $nombreCompleto, numeroHistoria: $numeroHistoria, role: $role, onboardingCompleted: $onboardingCompleted, tokensRestantes: $tokensRestantes, migrated: $migrated, termsAccepted: $termsAccepted)';
}


}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res>  {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) = _$UserModelCopyWithImpl;
@useResult
$Res call({
 String uid, String email, String nombre, String nombreCompleto, String numeroHistoria, String role, bool onboardingCompleted, int tokensRestantes, bool migrated, bool termsAccepted
});




}
/// @nodoc
class _$UserModelCopyWithImpl<$Res>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? email = null,Object? nombre = null,Object? nombreCompleto = null,Object? numeroHistoria = null,Object? role = null,Object? onboardingCompleted = null,Object? tokensRestantes = null,Object? migrated = null,Object? termsAccepted = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,nombreCompleto: null == nombreCompleto ? _self.nombreCompleto : nombreCompleto // ignore: cast_nullable_to_non_nullable
as String,numeroHistoria: null == numeroHistoria ? _self.numeroHistoria : numeroHistoria // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,tokensRestantes: null == tokensRestantes ? _self.tokensRestantes : tokensRestantes // ignore: cast_nullable_to_non_nullable
as int,migrated: null == migrated ? _self.migrated : migrated // ignore: cast_nullable_to_non_nullable
as bool,termsAccepted: null == termsAccepted ? _self.termsAccepted : termsAccepted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserModel].
extension UserModelPatterns on UserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserModel value)  $default,){
final _that = this;
switch (_that) {
case _UserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String email,  String nombre,  String nombreCompleto,  String numeroHistoria,  String role,  bool onboardingCompleted,  int tokensRestantes,  bool migrated,  bool termsAccepted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.uid,_that.email,_that.nombre,_that.nombreCompleto,_that.numeroHistoria,_that.role,_that.onboardingCompleted,_that.tokensRestantes,_that.migrated,_that.termsAccepted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String email,  String nombre,  String nombreCompleto,  String numeroHistoria,  String role,  bool onboardingCompleted,  int tokensRestantes,  bool migrated,  bool termsAccepted)  $default,) {final _that = this;
switch (_that) {
case _UserModel():
return $default(_that.uid,_that.email,_that.nombre,_that.nombreCompleto,_that.numeroHistoria,_that.role,_that.onboardingCompleted,_that.tokensRestantes,_that.migrated,_that.termsAccepted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String email,  String nombre,  String nombreCompleto,  String numeroHistoria,  String role,  bool onboardingCompleted,  int tokensRestantes,  bool migrated,  bool termsAccepted)?  $default,) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.uid,_that.email,_that.nombre,_that.nombreCompleto,_that.numeroHistoria,_that.role,_that.onboardingCompleted,_that.tokensRestantes,_that.migrated,_that.termsAccepted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserModel implements UserModel {
  const _UserModel({required this.uid, required this.email, this.nombre = '', this.nombreCompleto = '', this.numeroHistoria = '', this.role = 'cliente', this.onboardingCompleted = false, this.tokensRestantes = 0, this.migrated = false, this.termsAccepted = false});
  factory _UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

@override final  String uid;
@override final  String email;
@override@JsonKey() final  String nombre;
// Tolerante a null (devuelve vacío)
@override@JsonKey() final  String nombreCompleto;
// Tolerante a null
@override@JsonKey() final  String numeroHistoria;
// Tolerante a null
@override@JsonKey() final  String role;
@override@JsonKey() final  bool onboardingCompleted;
@override@JsonKey() final  int tokensRestantes;
@override@JsonKey() final  bool migrated;
@override@JsonKey() final  bool termsAccepted;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserModelCopyWith<_UserModel> get copyWith => __$UserModelCopyWithImpl<_UserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserModel&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.email, email) || other.email == email)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.nombreCompleto, nombreCompleto) || other.nombreCompleto == nombreCompleto)&&(identical(other.numeroHistoria, numeroHistoria) || other.numeroHistoria == numeroHistoria)&&(identical(other.role, role) || other.role == role)&&(identical(other.onboardingCompleted, onboardingCompleted) || other.onboardingCompleted == onboardingCompleted)&&(identical(other.tokensRestantes, tokensRestantes) || other.tokensRestantes == tokensRestantes)&&(identical(other.migrated, migrated) || other.migrated == migrated)&&(identical(other.termsAccepted, termsAccepted) || other.termsAccepted == termsAccepted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uid,email,nombre,nombreCompleto,numeroHistoria,role,onboardingCompleted,tokensRestantes,migrated,termsAccepted);

@override
String toString() {
  return 'UserModel(uid: $uid, email: $email, nombre: $nombre, nombreCompleto: $nombreCompleto, numeroHistoria: $numeroHistoria, role: $role, onboardingCompleted: $onboardingCompleted, tokensRestantes: $tokensRestantes, migrated: $migrated, termsAccepted: $termsAccepted)';
}


}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res> implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(_UserModel value, $Res Function(_UserModel) _then) = __$UserModelCopyWithImpl;
@override @useResult
$Res call({
 String uid, String email, String nombre, String nombreCompleto, String numeroHistoria, String role, bool onboardingCompleted, int tokensRestantes, bool migrated, bool termsAccepted
});




}
/// @nodoc
class __$UserModelCopyWithImpl<$Res>
    implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? email = null,Object? nombre = null,Object? nombreCompleto = null,Object? numeroHistoria = null,Object? role = null,Object? onboardingCompleted = null,Object? tokensRestantes = null,Object? migrated = null,Object? termsAccepted = null,}) {
  return _then(_UserModel(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,nombreCompleto: null == nombreCompleto ? _self.nombreCompleto : nombreCompleto // ignore: cast_nullable_to_non_nullable
as String,numeroHistoria: null == numeroHistoria ? _self.numeroHistoria : numeroHistoria // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,onboardingCompleted: null == onboardingCompleted ? _self.onboardingCompleted : onboardingCompleted // ignore: cast_nullable_to_non_nullable
as bool,tokensRestantes: null == tokensRestantes ? _self.tokensRestantes : tokensRestantes // ignore: cast_nullable_to_non_nullable
as int,migrated: null == migrated ? _self.migrated : migrated // ignore: cast_nullable_to_non_nullable
as bool,termsAccepted: null == termsAccepted ? _self.termsAccepted : termsAccepted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
