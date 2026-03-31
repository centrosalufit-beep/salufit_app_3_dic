// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signature_alert_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SignatureAlert)
const signatureAlertProvider = SignatureAlertProvider._();

final class SignatureAlertProvider
    extends $NotifierProvider<SignatureAlert, bool> {
  const SignatureAlertProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signatureAlertProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signatureAlertHash();

  @$internal
  @override
  SignatureAlert create() => SignatureAlert();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$signatureAlertHash() => r'4e3fde37b3c2e945f76374615c49e447c17d28b3';

abstract class _$SignatureAlert extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
