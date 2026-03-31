// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActivationController)
const activationControllerProvider = ActivationControllerProvider._();

final class ActivationControllerProvider
    extends $AsyncNotifierProvider<ActivationController, void> {
  const ActivationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activationControllerHash();

  @$internal
  @override
  ActivationController create() => ActivationController();
}

String _$activationControllerHash() =>
    r'c172351cc086d88843777d9803d087b90d382703';

abstract class _$ActivationController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
