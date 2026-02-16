// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_analysis_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

@ProviderFor(adminAnalysis)
const adminAnalysisProvider = AdminAnalysisProvider._();

final class AdminAnalysisProvider extends $FunctionalProvider<
        AsyncValue<List<AnalysisMetric>>,
        List<AnalysisMetric>,
        FutureOr<List<AnalysisMetric>>>
    with
        $FutureModifier<List<AnalysisMetric>>,
        $FutureProvider<List<AnalysisMetric>> {
  const AdminAnalysisProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'adminAnalysisProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$adminAnalysisHash();

  @$internal
  @override
  $FutureProviderElement<List<AnalysisMetric>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<AnalysisMetric>> create(Ref ref) {
    return adminAnalysis(ref);
  }
}

String _$adminAnalysisHash() => r'39facc27d785aae602d00d65f4a8b31280d0f0a9';

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
