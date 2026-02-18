// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(HomeTab)
const homeTabProvider = HomeTabProvider._();

final class HomeTabProvider extends $NotifierProvider<HomeTab, int> {
  const HomeTabProvider._()
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
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element = ref.element
        as $ClassProviderElement<AnyNotifier<int, int>, int, Object?, Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(BookingDate)
const bookingDateProvider = BookingDateProvider._();

final class BookingDateProvider
    extends $NotifierProvider<BookingDate, DateTime> {
  const BookingDateProvider._()
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
    final created = build();
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<DateTime, DateTime>, DateTime, Object?, Object?>;
    element.handleValue(ref, created);
  }
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
