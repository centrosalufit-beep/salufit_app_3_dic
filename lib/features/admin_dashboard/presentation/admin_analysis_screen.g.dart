// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_analysis_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AdminAnalysis)
final adminAnalysisProvider = AdminAnalysisProvider._();

final class AdminAnalysisProvider
    extends $AsyncNotifierProvider<AdminAnalysis, List<AnalysisMetric>> {
  AdminAnalysisProvider._()
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
  AdminAnalysis create() => AdminAnalysis();
}

String _$adminAnalysisHash() => r'8c1eb1620f59b6e62433ea4d32f635da5fde5a7c';

abstract class _$AdminAnalysis extends $AsyncNotifier<List<AnalysisMetric>> {
  FutureOr<List<AnalysisMetric>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<AnalysisMetric>>, List<AnalysisMetric>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<AnalysisMetric>>,
                List<AnalysisMetric>
              >,
              AsyncValue<List<AnalysisMetric>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
