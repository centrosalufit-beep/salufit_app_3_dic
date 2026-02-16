// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(patientRepository)
const patientRepositoryProvider = PatientRepositoryProvider._();

final class PatientRepositoryProvider extends $FunctionalProvider<
    PatientRepository,
    PatientRepository,
    PatientRepository> with $Provider<PatientRepository> {
  const PatientRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'patientRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$patientRepositoryHash();

  @$internal
  @override
  $ProviderElement<PatientRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PatientRepository create(Ref ref) {
    return patientRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PatientRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PatientRepository>(value),
    );
  }
}

String _$patientRepositoryHash() => r'e7071a22c393ce1d2b0162938d11c7b05b0f9642';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
