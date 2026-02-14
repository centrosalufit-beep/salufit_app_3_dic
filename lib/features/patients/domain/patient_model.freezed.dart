// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'patient_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Patient {
// ID: Obligatorio
  @JsonKey(name: 'legacy_id')
  String get id;
  String get email; // CAMPOS OPCIONALES CON DEFAULT
  String get firstName;
  String get lastName;
  String get fullName;
  String get phoneNumber;
  String get dni;
  int get tokens;
  bool get migrated;

  /// Create a copy of Patient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PatientCopyWith<Patient> get copyWith =>
      _$PatientCopyWithImpl<Patient>(this as Patient, _$identity);

  /// Serializes this Patient to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Patient &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.dni, dni) || other.dni == dni) &&
            (identical(other.tokens, tokens) || other.tokens == tokens) &&
            (identical(other.migrated, migrated) ||
                other.migrated == migrated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, email, firstName, lastName,
      fullName, phoneNumber, dni, tokens, migrated);

  @override
  String toString() {
    return 'Patient(id: $id, email: $email, firstName: $firstName, lastName: $lastName, fullName: $fullName, phoneNumber: $phoneNumber, dni: $dni, tokens: $tokens, migrated: $migrated)';
  }
}

/// @nodoc
abstract mixin class $PatientCopyWith<$Res> {
  factory $PatientCopyWith(Patient value, $Res Function(Patient) _then) =
      _$PatientCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'legacy_id') String id,
      String email,
      String firstName,
      String lastName,
      String fullName,
      String phoneNumber,
      String dni,
      int tokens,
      bool migrated});
}

/// @nodoc
class _$PatientCopyWithImpl<$Res> implements $PatientCopyWith<$Res> {
  _$PatientCopyWithImpl(this._self, this._then);

  final Patient _self;
  final $Res Function(Patient) _then;

  /// Create a copy of Patient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? fullName = null,
    Object? phoneNumber = null,
    Object? dni = null,
    Object? tokens = null,
    Object? migrated = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: null == firstName
          ? _self.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String,
      lastName: null == lastName
          ? _self.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _self.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      phoneNumber: null == phoneNumber
          ? _self.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String,
      dni: null == dni
          ? _self.dni
          : dni // ignore: cast_nullable_to_non_nullable
              as String,
      tokens: null == tokens
          ? _self.tokens
          : tokens // ignore: cast_nullable_to_non_nullable
              as int,
      migrated: null == migrated
          ? _self.migrated
          : migrated // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [Patient].
extension PatientPatterns on Patient {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Patient value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Patient() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Patient value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Patient():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Patient value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Patient() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            @JsonKey(name: 'legacy_id') String id,
            String email,
            String firstName,
            String lastName,
            String fullName,
            String phoneNumber,
            String dni,
            int tokens,
            bool migrated)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Patient() when $default != null:
        return $default(
            _that.id,
            _that.email,
            _that.firstName,
            _that.lastName,
            _that.fullName,
            _that.phoneNumber,
            _that.dni,
            _that.tokens,
            _that.migrated);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            @JsonKey(name: 'legacy_id') String id,
            String email,
            String firstName,
            String lastName,
            String fullName,
            String phoneNumber,
            String dni,
            int tokens,
            bool migrated)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Patient():
        return $default(
            _that.id,
            _that.email,
            _that.firstName,
            _that.lastName,
            _that.fullName,
            _that.phoneNumber,
            _that.dni,
            _that.tokens,
            _that.migrated);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            @JsonKey(name: 'legacy_id') String id,
            String email,
            String firstName,
            String lastName,
            String fullName,
            String phoneNumber,
            String dni,
            int tokens,
            bool migrated)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Patient() when $default != null:
        return $default(
            _that.id,
            _that.email,
            _that.firstName,
            _that.lastName,
            _that.fullName,
            _that.phoneNumber,
            _that.dni,
            _that.tokens,
            _that.migrated);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class _Patient implements Patient {
  const _Patient(
      {@JsonKey(name: 'legacy_id') required this.id,
      required this.email,
      this.firstName = '',
      this.lastName = '',
      this.fullName = '',
      this.phoneNumber = '',
      this.dni = '',
      this.tokens = 0,
      this.migrated = false});
  factory _Patient.fromJson(Map<String, dynamic> json) =>
      _$PatientFromJson(json);

// ID: Obligatorio
  @override
  @JsonKey(name: 'legacy_id')
  final String id;
  @override
  final String email;
// CAMPOS OPCIONALES CON DEFAULT
  @override
  @JsonKey()
  final String firstName;
  @override
  @JsonKey()
  final String lastName;
  @override
  @JsonKey()
  final String fullName;
  @override
  @JsonKey()
  final String phoneNumber;
  @override
  @JsonKey()
  final String dni;
  @override
  @JsonKey()
  final int tokens;
  @override
  @JsonKey()
  final bool migrated;

  /// Create a copy of Patient
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PatientCopyWith<_Patient> get copyWith =>
      __$PatientCopyWithImpl<_Patient>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PatientToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Patient &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.dni, dni) || other.dni == dni) &&
            (identical(other.tokens, tokens) || other.tokens == tokens) &&
            (identical(other.migrated, migrated) ||
                other.migrated == migrated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, email, firstName, lastName,
      fullName, phoneNumber, dni, tokens, migrated);

  @override
  String toString() {
    return 'Patient(id: $id, email: $email, firstName: $firstName, lastName: $lastName, fullName: $fullName, phoneNumber: $phoneNumber, dni: $dni, tokens: $tokens, migrated: $migrated)';
  }
}

/// @nodoc
abstract mixin class _$PatientCopyWith<$Res> implements $PatientCopyWith<$Res> {
  factory _$PatientCopyWith(_Patient value, $Res Function(_Patient) _then) =
      __$PatientCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'legacy_id') String id,
      String email,
      String firstName,
      String lastName,
      String fullName,
      String phoneNumber,
      String dni,
      int tokens,
      bool migrated});
}

/// @nodoc
class __$PatientCopyWithImpl<$Res> implements _$PatientCopyWith<$Res> {
  __$PatientCopyWithImpl(this._self, this._then);

  final _Patient _self;
  final $Res Function(_Patient) _then;

  /// Create a copy of Patient
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? fullName = null,
    Object? phoneNumber = null,
    Object? dni = null,
    Object? tokens = null,
    Object? migrated = null,
  }) {
    return _then(_Patient(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: null == firstName
          ? _self.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String,
      lastName: null == lastName
          ? _self.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _self.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      phoneNumber: null == phoneNumber
          ? _self.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String,
      dni: null == dni
          ? _self.dni
          : dni // ignore: cast_nullable_to_non_nullable
              as String,
      tokens: null == tokens
          ? _self.tokens
          : tokens // ignore: cast_nullable_to_non_nullable
              as int,
      migrated: null == migrated
          ? _self.migrated
          : migrated // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
