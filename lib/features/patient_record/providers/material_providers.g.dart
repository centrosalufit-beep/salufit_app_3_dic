// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DailyProgress)
const dailyProgressProvider = DailyProgressProvider._();

final class DailyProgressProvider
    extends $NotifierProvider<DailyProgress, List<String>> {
  const DailyProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyProgressHash();

  @$internal
  @override
  DailyProgress create() => DailyProgress();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$dailyProgressHash() => r'c5119f122c27fbe56dd37e1b88e12789aef7071c';

abstract class _$DailyProgress extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(MyAssignments)
const myAssignmentsProvider = MyAssignmentsProvider._();

final class MyAssignmentsProvider
    extends $StreamNotifierProvider<MyAssignments, List<Map<String, dynamic>>> {
  const MyAssignmentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myAssignmentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myAssignmentsHash();

  @$internal
  @override
  MyAssignments create() => MyAssignments();
}

String _$myAssignmentsHash() => r'a90a2f3e9f4fc44207ebe7ba5baabce14dab5e8f';

abstract class _$MyAssignments
    extends $StreamNotifier<List<Map<String, dynamic>>> {
  Stream<List<Map<String, dynamic>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<Map<String, dynamic>>>,
              List<Map<String, dynamic>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<Map<String, dynamic>>>,
                List<Map<String, dynamic>>
              >,
              AsyncValue<List<Map<String, dynamic>>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(exerciseDetails)
const exerciseDetailsProvider = ExerciseDetailsFamily._();

final class ExerciseDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          FutureOr<Map<String, dynamic>?>
        >
    with
        $FutureModifier<Map<String, dynamic>?>,
        $FutureProvider<Map<String, dynamic>?> {
  const ExerciseDetailsProvider._({
    required ExerciseDetailsFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'exerciseDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exerciseDetailsHash();

  @override
  String toString() {
    return r'exerciseDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>?> create(Ref ref) {
    final argument = this.argument as String?;
    return exerciseDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exerciseDetailsHash() => r'5cd9342ff20833735915f2f048d33fe91d691b5f';

final class ExerciseDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, dynamic>?>, String?> {
  const ExerciseDetailsFamily._()
    : super(
        retry: null,
        name: r'exerciseDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ExerciseDetailsProvider call(String? id) =>
      ExerciseDetailsProvider._(argument: id, from: this);

  @override
  String toString() => r'exerciseDetailsProvider';
}
