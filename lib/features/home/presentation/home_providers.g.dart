// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HomeTab)
final homeTabProvider = HomeTabProvider._();

final class HomeTabProvider extends $NotifierProvider<HomeTab, int> {
  HomeTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeTabProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeTabHash();

  @$internal
  @override
  HomeTab create() => HomeTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$homeTabHash() => r'af6f6238f9adfa0e4d1637d119472793310ee825';

abstract class _$HomeTab extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(BookingDate)
final bookingDateProvider = BookingDateProvider._();

final class BookingDateProvider
    extends $NotifierProvider<BookingDate, DateTime> {
  BookingDateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingDateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingDateHash();

  @$internal
  @override
  BookingDate create() => BookingDate();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$bookingDateHash() => r'932b93a8806bc2b67dc6845b30580e391ef588c0';

abstract class _$BookingDate extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
