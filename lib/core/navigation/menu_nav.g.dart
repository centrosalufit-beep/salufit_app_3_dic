// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_nav.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MenuIndex)
const menuIndexProvider = MenuIndexProvider._();

final class MenuIndexProvider extends $NotifierProvider<MenuIndex, int> {
  const MenuIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuIndexHash();

  @$internal
  @override
  MenuIndex create() => MenuIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$menuIndexHash() => r'b819d7c12b69d8b2dced577278014ff0aa45b4aa';

abstract class _$MenuIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
