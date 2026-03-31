// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userTokenSync)
const userTokenSyncProvider = UserTokenSyncProvider._();

final class UserTokenSyncProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  const UserTokenSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userTokenSyncProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userTokenSyncHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return userTokenSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$userTokenSyncHash() => r'b2f0959d23454d1b74742c5353a5fabda4c3dc7d';
